package hu.bme.mit.gamma.scxml.transformation

import ac.soton.scxml.ScxmlParallelType
import ac.soton.scxml.ScxmlScxmlType
import ac.soton.scxml.ScxmlStateType
import ac.soton.scxml.ScxmlTransitionType
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.SynchronousStatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Map

import static com.google.common.base.Preconditions.checkNotNull
import ac.soton.scxml.ScxmlFinalType

class Traceability {
	
	// Root element of the SCXML statechart model to transform.
	// This Traceability class will be able to store multiple
	// ScxmlScxmlType - SynchronousStatechartDefinition pairs, but for now,
	// we assume only one SCMXL statechart to be transformed (from an <scxml> root element).
	protected final ScxmlScxmlType scxmlRoot
	
	protected final Map<ScxmlScxmlType, SynchronousStatechartDefinition> statechartDefinitions = newHashMap
	protected final Map<ScxmlParallelType, State> parallels = newHashMap
	protected final Map<ScxmlStateType, State> states = newHashMap
	protected final Map<ScxmlFinalType, State> finals = newHashMap
	protected final Map<ScxmlTransitionType, Transition> transitions = newHashMap
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	// <scxml> - Synchronous Statechart Definition
	
	new(ScxmlScxmlType scxmlRoot) {
		this.scxmlRoot = scxmlRoot
	}
	
	def getScxmlRoot() {
		return scxmlRoot
	}
	
	def put(ScxmlScxmlType scxmlRoot, SynchronousStatechartDefinition gammaStatechart) {
		checkNotNull(scxmlRoot)
		checkNotNull(gammaStatechart)
		statechartDefinitions += scxmlRoot -> gammaStatechart
	}
	
	def getStatechartDefinition(ScxmlScxmlType scxmlRoot) {
		checkNotNull(scxmlRoot)
		val gammaStatechart = statechartDefinitions.get(scxmlRoot)
		checkNotNull(gammaStatechart)
		return gammaStatechart
	}
	
	// <parallel> - State (with orthogonal Regions)
	
	def put(ScxmlParallelType scxmlParallel, State gammaParallel) {
		checkNotNull(scxmlParallel)
		checkNotNull(gammaParallel)
		parallels += scxmlParallel -> gammaParallel
	}
	
	def getParallel(ScxmlParallelType scxmlParallel) {
		checkNotNull(scxmlParallel)
		val gammaParallel = parallels.get(scxmlParallel)
		checkNotNull(gammaParallel)
		return gammaParallel
	}
	
	def getParallelById(String scxmlParallelId) {
		checkNotNull(scxmlParallelId)
		val keySet = states.keySet
		val scxmlParallel = keySet.findFirst[parallel | parallel.id == scxmlParallelId]
		checkNotNull(scxmlParallel)
		return getState(scxmlParallel)
	}
	
	// <state> - State
	
	def put(ScxmlStateType scxmlState, State gammaState) {
		checkNotNull(scxmlState)
		checkNotNull(gammaState)
		states += scxmlState -> gammaState
	}
	
	def getState(ScxmlStateType scxmlState) {
		checkNotNull(scxmlState)
		val gammaState = states.get(scxmlState)
		checkNotNull(gammaState)
		return gammaState
	}
	
	def getStateById(String scxmlStateId) {
		checkNotNull(scxmlStateId)
		val keySet = states.keySet
		val scxmlState = keySet.findFirst[state | state.id == scxmlStateId]
		checkNotNull(scxmlState)
		return getState(scxmlState)
	}
	
	// <final> - State
	
	def put(ScxmlFinalType scxmlFinal, State gammaFinal) {
		checkNotNull(scxmlFinal)
		checkNotNull(gammaFinal)
		finals += scxmlFinal -> gammaFinal
	}
	
	def getFinalState(ScxmlFinalType scxmlFinal) {
		checkNotNull(scxmlFinal)
		val gammaFinal = finals.get(scxmlFinal)
		checkNotNull(gammaFinal)
		return gammaFinal
	}
	
	def getFinalById(String scxmlFinalId) {
		checkNotNull(scxmlFinalId)
		val keySet = finals.keySet
		val scxmlFinal = keySet.findFirst[final | final.id == scxmlFinalId]
		checkNotNull(scxmlFinal)
		return getFinalState(scxmlFinal)
	}
	
	// <transition> - Transition
	
	def put(ScxmlTransitionType scxmlTransition, Transition gammaTransition) {
		checkNotNull(scxmlTransition)
		checkNotNull(gammaTransition)
		transitions += scxmlTransition -> gammaTransition
	}
	
	def getTransition(ScxmlTransitionType scxmlTransition) {
		checkNotNull(scxmlTransition)
		val gammaTransition = transitions.get(scxmlTransition)
		checkNotNull(gammaTransition)
		return gammaTransition
	}
	
}