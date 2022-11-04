package hu.bme.mit.gamma.scxml.transformation

import ac.soton.scxml.ScxmlInvokeType
import ac.soton.scxml.ScxmlScxmlType
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Interface
import java.util.Map

import static com.google.common.base.Preconditions.checkNotNull
import org.eclipse.emf.common.util.URI

class CompositeTraceability {
	
	// Root element of the composite SCXML statechart model to transform.
	protected final ScxmlScxmlType scxmlRoot
	
	// Resulting root component
	protected AsynchronousComponent rootComponent
	
	// TODO Add interfaces, events, ports, bindings and channels
	// (Needed for the declarations package and serialization of the components package.)
	
	protected final Map<String, StatechartTraceability> statecharts = newHashMap
	protected final Map<ScxmlInvokeType, AsynchronousComponentInstance> instances = newHashMap
	
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
	
	def getTraceability(ScxmlScxmlType scxmlRoot) {
		checkNotNull(scxmlRoot)
		val statechartTraceability = statecharts.values.filter[it.scxmlRoot === scxmlRoot].head
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
		return interfaces.values
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