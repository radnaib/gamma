package hu.bme.mit.gamma.scxml.transformation

import ac.soton.scxml.HistoryTypeDatatype
import ac.soton.scxml.ScxmlFinalType
import ac.soton.scxml.ScxmlHistoryType
import ac.soton.scxml.ScxmlInitialType
import ac.soton.scxml.ScxmlParallelType
import ac.soton.scxml.ScxmlScxmlType
import ac.soton.scxml.ScxmlStateType
import ac.soton.scxml.ScxmlTransitionType
import ac.soton.scxml.TransitionTypeDatatype
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.ControlFunction
import hu.bme.mit.gamma.statechart.composite.DiscardStrategy
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures
import hu.bme.mit.gamma.statechart.statechart.EntryState
import hu.bme.mit.gamma.statechart.statechart.InitialState
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.SynchronousStatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import java.math.BigInteger
import java.util.logging.Logger

import static ac.soton.scxml.ScxmlModelDerivedFeatures.*
import static hu.bme.mit.gamma.scxml.transformation.Namings.*
import java.util.logging.Level

// TODO Scoping in variable transformation and assignment
// TODO History, parallel
class ScxmlToGammaStatechartTransformer extends AtomicElementTransformer {
	
	protected final extension ActionTransformer actionTransformer
	protected final extension DataTransformer dataTransformer
	protected final extension TriggerTransformer triggerTransformer
	
	// Root element of the SCXML statechart model to transform
	protected final ScxmlScxmlType scxmlRoot
	
	// Asynchronous wrapper component around the synchronous statechart definition
	protected AsynchronousAdapter adapter
	
	// Root element of the Gamma statechart definition as the transformation result
	protected final SynchronousStatechartDefinition gammaStatechart
	
	new(ScxmlScxmlType scxmlRoot, StatechartTraceability traceability) {
		super(traceability)
		
		this.scxmlRoot = scxmlRoot
		this.adapter = null
		this.gammaStatechart = createSynchronousStatechartDefinition => [
			it.name = getStatechartName(scxmlRoot)
		]
		
		this.actionTransformer = new ActionTransformer(traceability)
		this.dataTransformer = new DataTransformer(traceability)
		this.triggerTransformer = new TriggerTransformer(traceability)
	}
	
	// Transformation of the SCXML root element and its contents recursively
	def execute() {
		traceability.setStatechart(gammaStatechart)
				
		logger.log(Level.INFO, "Transforming <scxml> root element (" + scxmlRoot.name + ")")
		
		val datamodels = scxmlRoot.datamodel
		if (datamodels !== null) {
			val datamodel = datamodels.head
			if (datamodel !== null) {
				val dataElements = getDataElements(datamodel)
				for (data : dataElements) {
					val gammaVariableDeclaration = dataTransformer.transform(data)
					gammaStatechart.variableDeclarations += gammaVariableDeclaration
				}
			}
		}
		
		val mainRegion = createRegion => [
			it.name = getRegionName(scxmlRoot.name)
		]
		gammaStatechart.regions += mainRegion
		
		val scxmlStateNodes = getStateNodes(scxmlRoot)
		for (scxmlStateNode : scxmlStateNodes) {
			if (isParallel(scxmlStateNode)) {
				val parallel = scxmlStateNode as ScxmlParallelType
				mainRegion.stateNodes += parallel.transformParallel
			}
			else if (isState(scxmlStateNode)) {
				val state = scxmlStateNode as ScxmlStateType
				mainRegion.stateNodes += state.transformState
			}
			else if (isFinal(scxmlStateNode)) {
				val final = scxmlStateNode as ScxmlFinalType
				mainRegion.stateNodes += final.transformFinal
			}
			else {
				throw new IllegalArgumentException(
					"Object " + scxmlStateNode + " is of unknown SCXML <state> type.")
			}
		}
		
		val transitions = getAllTransitions(scxmlRoot)
		for (transition : transitions) {
			transition.transformTransition
		}
		
		// Transform the SCXML root element's initial attribute,
		// or select its first child as initial state if it is not present.
		val gammaInitial = createInitialState => [
			it.name = getInitialName(scxmlRoot)
		]
		mainRegion.stateNodes += gammaInitial	
		
		val scxmlInitialAttribute = scxmlRoot.initial
		val scxmlFirstInitialAttribute = scxmlInitialAttribute?.head
		if (scxmlFirstInitialAttribute !== null) {
			val gammaInitialTarget = traceability.getStateNodeById(scxmlFirstInitialAttribute)
			gammaInitial.createTransition(gammaInitialTarget)
		}
		else {
			val firstScxmlStateChild = getFirstChildStateNode(scxmlRoot) as ScxmlStateType
			val gammaInitialTarget = traceability.getState(firstScxmlStateChild)
			gammaInitial.createTransition(gammaInitialTarget)
		}
		
		// Add all transitions from initial states of Gamma compound states
		// specified by scxml initial attributes or document order
		gammaStatechart.transitions += traceability.getInitialTransitions
		
		// Add all ports from traceability
		if (traceability.getDefaultPort !== null) {
			gammaStatechart.ports += traceability.getDefaultPort
		}
		gammaStatechart.ports += traceability.defaultInterfacePorts.values
		gammaStatechart.ports += traceability.ports.values
		
		val adapter = wrapIntoAdapter
		traceability.adapter = adapter
		
		return traceability
	}
	
	protected def AsynchronousAdapter wrapIntoAdapter() {
		adapter = gammaStatechart.wrapIntoAdapter(getAdapterName(scxmlRoot))
		
		// Set control specification
		val controlSpecification = compositeModelFactory.createControlSpecification
		controlSpecification.trigger = interfaceModelFactory.createAnyTrigger
		controlSpecification.controlFunction = ControlFunction.RUN_ONCE
		
		adapter.controlSpecifications += controlSpecification
		
		// Create internal event queue
		// TODO Check capacity and priority
		val internalEventQueue = compositeModelFactory.createMessageQueue
		internalEventQueue.name = getInternalEventQueueName(scxmlRoot)
		internalEventQueue.eventDiscardStrategy = DiscardStrategy.INCOMING
		internalEventQueue.priority = BigInteger.TWO
		internalEventQueue.capacity = expressionUtil.toIntegerLiteral(10)
		
		// TODO Add only internal ports
		for (port : StatechartModelDerivedFeatures.getAllPortsWithInput(gammaStatechart)) {
			val reference = statechartModelFactory.createAnyPortEventReference
			reference.port = port
			internalEventQueue.eventReferences += reference
		}
		
		adapter.messageQueues += internalEventQueue
		
		// Create external event queue
		// TODO Check capacity and priority
		val externalEventQueue = compositeModelFactory.createMessageQueue
		externalEventQueue.name = getExternalEventQueueName(scxmlRoot)
		externalEventQueue.eventDiscardStrategy = DiscardStrategy.INCOMING
		externalEventQueue.priority = BigInteger.ONE
		externalEventQueue.capacity = expressionUtil.toIntegerLiteral(10)
		
		// TODO Add only external ports
		for (port : StatechartModelDerivedFeatures.getAllPortsWithInput(gammaStatechart)) {
			val reference = statechartModelFactory.createAnyPortEventReference
			reference.port = port
			externalEventQueue.eventReferences += reference
		}
		
		adapter.messageQueues.add(externalEventQueue)
		
		return adapter
	}
	
	protected def State transformParallel(ScxmlParallelType parallelNode) {
		logger.log(Level.INFO, "Transforming <parallel> element (" + parallelNode.id + ")")
		
		val gammaParallel = createState => [
			it.name = getParallelName(parallelNode)
		]
		
		val scxmlStateNodes = getStateNodes(parallelNode)
		for (scxmlStateNode : scxmlStateNodes) {
			val region = createRegion => [
				it.name = getRegionName(gammaParallel.name)
			]
			gammaParallel.regions += region
			
			if (isParallel(scxmlStateNode)) {
				val parallel = scxmlStateNode as ScxmlParallelType
				region.stateNodes += parallel.transformParallel
			}
			else if (isState(scxmlStateNode)) {
				val state = scxmlStateNode as ScxmlStateType
				region.stateNodes += state.transformState
			}
			else if (isFinal(scxmlStateNode)) {
				val final = scxmlStateNode as ScxmlFinalType
				region.stateNodes += final.transformFinal
			}
			else {
				throw new IllegalArgumentException(
					"Object " + scxmlStateNode + " is of unknown SCXML <state> type.")
			}
		}
		
		// TODO Transform history pseudo-states (by adding a wrapper compound state perhaps)
		// Initial-ok kicserélése a gyerek state-ekben, amely parallelekben találok historyt
		// Vagy history node hozzáadása minden gyerek régióhoz, ha van kívül history?
		/*val scxmlHistoryStates = parallelNode.history
		for (scxmlHistoryState : scxmlHistoryStates) {
			
		}*/
		
		// Transform onentry and onexit handlers
		val onentryActions = parallelNode.onentry
		for (onentryAction : onentryActions) {
			if (onentryAction !== null) {
				gammaParallel.entryActions += onentryAction.transformOnentry
			}
		}
	
		val onexitActions = parallelNode.onexit
		for (onexitAction : onexitActions) {
			if (onexitAction !== null) {
				gammaParallel.exitActions += onexitAction.transformOnexit
			}
		}
		
		traceability.put(parallelNode, gammaParallel)
		
		return gammaParallel
	}
	
	protected def State transformState(ScxmlStateType scxmlState) {
		logger.log(Level.INFO, "Transforming <state> element (" + scxmlState.id + ")")
		
		val gammaState = createState => [
			it.name = getStateName(scxmlState)
		]
		
		if (isCompoundState(scxmlState)) {
			val region = createRegion => [
				it.name = getRegionName(gammaState.name)
			]
			gammaState.regions += region
				
			val scxmlStateNodes = getStateNodes(scxmlState)
			for (scxmlStateNode : scxmlStateNodes) {
				if (isParallel(scxmlStateNode)) {
					val parallel = scxmlStateNode as ScxmlParallelType
					region.stateNodes += parallel.transformParallel
				}
				else if (isState(scxmlStateNode)) {
					val state = scxmlStateNode as ScxmlStateType
					region.stateNodes += state.transformState
				}
				else if (isFinal(scxmlStateNode)) {
					val final = scxmlStateNode as ScxmlFinalType
					region.stateNodes += final.transformFinal
				}
				else {
					throw new IllegalArgumentException(
						"Object " + scxmlStateNode + " is of unknown SCXML <state> type.")
				}
			}
			
			// Transform history pseudo-states
			val scxmlHistoryStates = scxmlState.history
			for (scxmlHistoryState : scxmlHistoryStates) {
				region.stateNodes += scxmlHistoryState.transform
			}
			
			// Transform the state's initial element or attribute,
			// or select its first child as initial state if neither one above is present.
			val scxmlInitialElement = scxmlState.initial.head
			if (scxmlInitialElement !== null) {
				region.stateNodes += scxmlInitialElement.transform
			}
			else {
				val gammaInitial = createInitialState => [
					it.name = getInitialName(scxmlState)
				]
				region.stateNodes += gammaInitial	
				
				val scxmlInitialAttribute = scxmlState.initial1.head
				if (scxmlInitialAttribute !== null) {
					val gammaInitialTarget = traceability.getStateNodeById(scxmlInitialAttribute)
					val initialTransition = gammaInitial.createTransition(gammaInitialTarget)
					traceability.putInitialTransition(initialTransition)
				}
				else {
					val firstScxmlStateChild = getFirstChildStateNode(scxmlState) as ScxmlStateType
					val gammaInitialTarget = traceability.getState(firstScxmlStateChild)
					val initialTransition = gammaInitial.createTransition(gammaInitialTarget)
					traceability.putInitialTransition(initialTransition)
				}
			}
		}
			
		// Transform onentry and onexit handlers
		val onentryActions = scxmlState.onentry
		for (onentryAction : onentryActions) {
			if (onentryAction !== null) {
				gammaState.entryActions += onentryAction.transformOnentry
			}
		}

		val onexitActions = scxmlState.onexit
		for (onexitAction : onexitActions) {
			if (onexitAction !== null) {
				gammaState.exitActions += onexitAction.transformOnexit
			}
		}
		
		traceability.put(scxmlState, gammaState)
		
		return gammaState
	}
	
	protected def State transformFinal(ScxmlFinalType scxmlFinal) {
		logger.log(Level.INFO, "Transforming <final> element (" + scxmlFinal.id + ")")
		
		val gammaFinal = createState => [
			it.name = getFinalName(scxmlFinal)
		]
		
		// Transform onentry and onexit handlers
		val onentryActions = scxmlFinal.onentry
		for (onentryAction : onentryActions) {
			if (onentryAction !== null) {
				gammaFinal.entryActions += onentryAction.transformOnentry
			}
		}

		val onexitActions = scxmlFinal.onexit
		for (onexitAction : onexitActions) {
			if (onexitAction !== null) {
				gammaFinal.exitActions += onexitAction.transformOnexit
			}
		}
		
		traceability.put(scxmlFinal, gammaFinal)
		
		return gammaFinal
	}
	
	protected def InitialState transform(ScxmlInitialType scxmlInitial) {
		logger.log(Level.INFO, "Transforming <initial> element")
		
		val parentState = getParentState(scxmlInitial)
		val gammaInitial = createInitialState => [
			it.name = getInitialName(parentState)
		]
		
		traceability.put(scxmlInitial, gammaInitial)
		
		return gammaInitial
	}
	
	protected def EntryState transform(ScxmlHistoryType scxmlHistory) {
		logger.log(Level.INFO, "Transforming <history> element (" + scxmlHistory.id + ")")
		
		if (scxmlHistory.type == HistoryTypeDatatype.SHALLOW) {
			val gammaShallowHistory = createShallowHistoryState => [
				it.name = getShallowHistoryName(scxmlHistory)
			]
			
			traceability.put(scxmlHistory, gammaShallowHistory)
			return gammaShallowHistory
		}
		else {
			val gammaDeepHistory = createDeepHistoryState => [
				it.name = getDeepHistoryName(scxmlHistory)
			]
			
			traceability.put(scxmlHistory, gammaDeepHistory)
			return gammaDeepHistory
		}
	}
	
	// Internal transitions are not supported by the transformer.
	protected def Transition transformTransition(ScxmlTransitionType transition) {
		if (transition.type == TransitionTypeDatatype.INTERNAL) {
			throw new IllegalArgumentException(
				"Transforming internal transition " + transition + " is not supported.")
		}
		
		val sourceState = getTransitionSource(transition)
		val targetId = transition.target.head
		
		val gammaSource = traceability.getStateNode(sourceState)
		val gammaTarget = traceability.getStateNodeById(targetId)

		logger.log(Level.INFO, "Transforming transition" + gammaSource.name + " -> " + gammaTarget.name)

		val gammaTransition = gammaSource.createTransition(gammaTarget)
		
		// Transform event trigger if present
		val eventName = transition.event
		if (!eventName.nullOrEmpty) {
			val eventTrigger = transformTrigger(eventName)
			gammaTransition.trigger = eventTrigger
		}
		
		// Transform guard if present
		val guardStr = transition.cond
		if (!guardStr.nullOrEmpty) {
			val gammaGuardExpression = expressionLanguageParser.parse(guardStr, traceability.variables)
			gammaTransition.guard = gammaGuardExpression
		}
		
		// TODO for all types of actions
		val effects = transition.assign + transition.raise
		if (!effects.nullOrEmpty) {
			gammaTransition.effects += effects.transformBlock
		}
		//

		traceability.put(transition, gammaTransition)
			
		return gammaTransition
	}
	
}