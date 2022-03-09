package hu.bme.mit.gamma.scxml.transformation

import ac.soton.scxml.ScxmlParallelType
import ac.soton.scxml.ScxmlScxmlType
import ac.soton.scxml.ScxmlStateType
import ac.soton.scxml.ScxmlTransitionType

import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.SynchronousStatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition

import java.util.logging.Level

import static ac.soton.scxml.ScxmlModelDerivedFeatures.*
import java.util.HashMap

class ScxmlToGammaStatechartTransformer extends AbstractTransformer {
	
	// Root element of the SCXML statechart model to transform
	protected final ScxmlScxmlType scxmlRoot
	
	// Root element of the Gamma statechart definition as the transformation result
	protected final SynchronousStatechartDefinition gammaStatechart
	
	new(ScxmlScxmlType scxmlRoot) {
		this(scxmlRoot,
			new Traceability(scxmlRoot)
		)
	}
	
	new(ScxmlScxmlType scxmlRoot, Traceability traceability) {
		super(traceability)
		
		this.scxmlRoot = scxmlRoot
		this.gammaStatechart = createSynchronousStatechartDefinition => [
			it.name = scxmlRoot.name
		]
	}
	
	def execute() {
		traceability.put(scxmlRoot, gammaStatechart)
		
		logger.log(Level.INFO, "Transforming <scxml> root element (" + scxmlRoot.name + ")")
		
		val mainRegion = createRegion => [
			it.name = scxmlRoot.name
		]
		gammaStatechart.regions += mainRegion
		
		val stateNodes = getStateNodes(scxmlRoot)
		for (stateNode : stateNodes) {
			if (isParallel(stateNode)) {
				val parallel = stateNode as ScxmlParallelType
				mainRegion.stateNodes += parallel.transformParallel
			}
			else if (stateNode instanceof ScxmlStateType) {
				mainRegion.stateNodes += stateNode.transformState
			}
			else if (isFinal(stateNode)) { // TODO
				/*val final = stateNode as ScxmlFinalType
				mainRegion.stateNodes += final.transformFinal*/
			}
			else {
				throw new IllegalArgumentException(
					"Object " + stateNode + " is of unknown SCXML <state> type.")
			}
		}
		
		val transitions = getAllTransitions(scxmlRoot)
		for (transition : transitions) {
			transition.transform
		}
		
		return traceability
	}
	
	def State transformParallel(ScxmlParallelType parallelNode) {
		logger.log(Level.INFO, "Transforming <parallel> element (" + parallelNode.id + ")")
		
		val gammaParallel = createState => [
			it.name = parallelNode.id
		]
		
		val stateNodes = getStateNodes(parallelNode)
		
		for (stateNode : stateNodes) {
			val region = createRegion => [
				it.name = gammaParallel.name + "Region" // TODO
			]
			gammaParallel.regions += region
			
			if (isParallel(stateNode)) {
				val parallel = stateNode as ScxmlParallelType
				region.stateNodes += parallel.transformParallel
			}
			else if (isState(stateNode)) {
				val state = stateNode as ScxmlStateType
				region.stateNodes += state.transformState
			}
			else if (isFinal(stateNode)) {	// TODO
				/*val final = stateNode as ScxmlFinalType
				region.stateNodes += final.transformFinal*/
			}
			else {
				throw new IllegalArgumentException(
					"Object " + stateNode + " is of unknown SCXML <state> type.")
			}
		}
		
		traceability.put(parallelNode, gammaParallel)
		
		return gammaParallel
	}
	
	def State transformState(ScxmlStateType scxmlState) {
		logger.log(Level.INFO, "Transforming <state> element (" + scxmlState.id + ")")
		
		val gammaState = createState => [
			it.name = scxmlState.id
		]
		
		if (isCompoundState(scxmlState)) {
			val region = createRegion => [
				it.name = gammaState.name + "Region" // TODO
			]
			gammaState.regions += region
				
			val stateNodes = getStateNodes(scxmlState)
			
			for (stateNode : stateNodes) {
				if (isParallel(stateNode)) {
					val parallel = stateNode as ScxmlParallelType
					region.stateNodes += parallel.transformParallel
				}
				else if (isState(stateNode)) {
					val state = stateNode as ScxmlStateType
					region.stateNodes += state.transformState
				}
				else if (isFinal(stateNode)) {	// TODO
					/*val final = stateNode as ScxmlFinalType
					region.stateNodes += final.transformFinal*/
				}
				else {
					throw new IllegalArgumentException(
						"Object " + stateNode + " is of unknown SCXML <state> type.")
				}
			}
		}
		
		traceability.put(scxmlState, gammaState)
		
		return gammaState
	}
	
	protected def Transition transform(ScxmlTransitionType transition) {
		// For now, only ScxmlStateType is considered as a type of a transition source. TODO
		val sourceId = getParentStateNodeId(transition)
		val targetId = transition.target.head
		
		if (sourceId !== null) {
			val gammaSource = traceability.getStateById(sourceId)
			val gammaTarget = traceability.getStateById(targetId)
			
			logger.log(Level.INFO, "Transforming transition" + sourceId + " -> " + targetId)
			
			val gammaTransition = gammaSource.createTransition(gammaTarget)
			
			val guardStr = transition.cond
			if (guardStr !== null) {
				val gammaGuardExpression = conditionalLanguageParser
											.parse(guardStr, new HashMap)
				gammaTransition.guard = gammaGuardExpression
			}
			
			traceability.put(transition, gammaTransition)
			
			return gammaTransition
		}
		
		return null
	}
	
}