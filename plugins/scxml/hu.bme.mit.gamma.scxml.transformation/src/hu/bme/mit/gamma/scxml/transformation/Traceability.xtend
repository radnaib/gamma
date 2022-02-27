package hu.bme.mit.gamma.scxml.transformation

import ac.soton.scxml.ScxmlScxmlType
import ac.soton.scxml.ScxmlStateType

import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.SynchronousStatechartDefinition

import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Map

import static com.google.common.base.Preconditions.checkNotNull

class Traceability {
	
	// Root element of the SCXML statechart model to transform.
	// This Traceability class will be able to store multiple
	// ScxmlScxmlType - SynchronousStatechartDefinition pairs, but for now,
	// we assume only one SCMXL statechart to be transformed (from an <scxml> root element).
	protected final ScxmlScxmlType scxmlRoot
	
	protected final Map<ScxmlScxmlType, SynchronousStatechartDefinition> statechartDefinitions = newHashMap
	protected final Map<ScxmlStateType, State> states = newHashMap
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	
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
	
}