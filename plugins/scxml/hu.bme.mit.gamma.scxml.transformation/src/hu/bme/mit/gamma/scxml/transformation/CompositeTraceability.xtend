package hu.bme.mit.gamma.scxml.transformation

import ac.soton.scxml.ScxmlInvokeType
import ac.soton.scxml.ScxmlScxmlType
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Interface
import hu.bme.mit.gamma.statechart.interface_.Port
import java.util.Map

import static com.google.common.base.Preconditions.checkNotNull

class CompositeTraceability {
	
	// Root element of the composite SCXML statechart model to transform.
	protected final ScxmlScxmlType scxmlRoot
	
	// Resulting root component
	protected AsynchronousComponent rootComponent
	
	// TODO Add interfaces, events, ports, bindings and channels
	// (Needed for the declarations package and serialization of the components package.)
	
	protected final Map<String, StatechartTraceability> statecharts = newHashMap
	protected final Map<ScxmlInvokeType, AsynchronousComponentInstance> instances = newHashMap
	protected final Map<String, Port> ports = newHashMap
	
	// Global mappings: Interfaces, events, declarations
	protected final Map<String, Interface> interfaces = newHashMap
	protected final Map<Pair<Interface, String>, Event> inEvents = newHashMap
	protected final Map<Pair<Interface, String>, Event> outEvents = newHashMap
	
	// <scxml> - Asynchronous Component
	new(ScxmlScxmlType scxmlRoot) {
		this.scxmlRoot = scxmlRoot
	}

	def getScxmlRoot() {
		return scxmlRoot
	}
	
	def getRootComponent() {
		return rootComponent
	}
	
	def setRootComponent(AsynchronousComponent rootComponent) {
		this.rootComponent = rootComponent
	}
	
	// String URI of the SCXML statechart definition source - Statechart Traceability
	def putTraceability(String statechartUri, StatechartTraceability statechartTraceability) {
		checkNotNull(statechartUri)
		checkNotNull(statechartTraceability)
		statecharts += statechartUri -> statechartTraceability
	}
	
	def getTraceability(String statechartUri) {
		checkNotNull(statechartUri)
		val statechartTraceability = statecharts.get(statechartUri)
		checkNotNull(statechartTraceability)
		return statechartTraceability
	}
	
	// TODO Simplify map structure and getter.
	def getTraceabilityById(String scxmlInvokeId) {
		checkNotNull(scxmlInvokeId)
		val invoke = instances.keySet.findFirst[invoke | invoke.id == scxmlInvokeId]
		checkNotNull(invoke)
		val statechartTraceability = statecharts.filter[source, _ | source == invoke.src].values.head
		checkNotNull(statechartTraceability)
		return statechartTraceability
	}
	
	def getTraceability(ScxmlScxmlType scxmlRoot) {
		checkNotNull(scxmlRoot)
		val statechartTraceability = statecharts.values.findFirst[it.scxmlRoot === scxmlRoot]
		checkNotNull(statechartTraceability)
		return statechartTraceability
	}
	
	def containsTraceability(String statechartUri) {
		checkNotNull(statechartUri)
		return statecharts.containsKey(statechartUri)
	}
	
	// <invoke> - Asynchronous Component Instance
	def putComponentInstance(ScxmlInvokeType scxmlInvoke, AsynchronousComponentInstance instance) {
		checkNotNull(scxmlInvoke)
		checkNotNull(instance)
		instances += scxmlInvoke -> instance
	}
	
	def getComponentInstance(ScxmlInvokeType scxmlInvoke) {
		checkNotNull(scxmlInvoke)
		val instance = instances.get(scxmlInvoke)
		checkNotNull(instance)
		return instance
	}
	
	def getComponentInstance(String scxmlInvokeId) {
		checkNotNull(scxmlInvokeId)
		val instance = instances.filter[invoke, _ | invoke.id == scxmlInvokeId].values.head
		checkNotNull(instance)
		return instance
	}
	
	// Ports by string identifier (for event strings like 'port.interface.event)
	def putPort(String scxmlPortName, Port gammaPort) {
		checkNotNull(scxmlPortName)
		checkNotNull(gammaPort)
		ports += scxmlPortName -> gammaPort
	}
	
	def getPort(String scxmlPortName) {
		checkNotNull(scxmlPortName)
		val gammaPort = ports.get(scxmlPortName)
		checkNotNull(gammaPort)
		return gammaPort
	}
	
	def containsPort(String scxmlPortName) {
		checkNotNull(scxmlPortName)
		return ports.containsKey(scxmlPortName)
	}
	
	//
	
	def getInEvents() {
		return inEvents
	}
	
	def getOutEvents() {
		return outEvents
	}
	
	def getInstances() {
		return instances
	}
	
	def getStatecharts() {
		return statecharts.values.toList
	}
	
	//
	
	def getInterfaces() {
		val statechartTraceabilities = statecharts.values
		return (interfaces.values
			+ statechartTraceabilities.map[it.defaultInterface]
			+ statechartTraceabilities.map[it.defaultInterfacePorts.keySet].flatten
		).toSet
	}
	
	def getComponents() {
		val statechartTraceabilities = statecharts.values
		return (instances.values.map[it.getType]
			+ statechartTraceabilities.map[it.getAdapter]
			+ statechartTraceabilities.map[it.getStatechart]
		).toSet
	}
	
	def createStatechartTraceability(ScxmlScxmlType scxmlRoot) {
		return new StatechartTraceability(scxmlRoot,
			interfaces, inEvents, outEvents
		)
	}
}