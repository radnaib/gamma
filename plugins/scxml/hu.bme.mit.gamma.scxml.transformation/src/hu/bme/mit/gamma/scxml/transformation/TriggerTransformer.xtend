package hu.bme.mit.gamma.scxml.transformation

import hu.bme.mit.gamma.statechart.interface_.Interface
import hu.bme.mit.gamma.statechart.interface_.Port

class TriggerTransformer extends AtomicElementTransformer {
	
	protected final extension PortTransformer portTransformer
	protected final extension InterfaceTransformer interfaceTransformer
	protected final extension EventTransformer eventTransformer
	
	new(StatechartTraceability traceability) {
		super(traceability)
		
		this.portTransformer = new PortTransformer(traceability)
		this.interfaceTransformer = new InterfaceTransformer(traceability)
		this.eventTransformer = new EventTransformer(traceability)
	}
	
	// TODO sanitize and check eventString
	def transformTrigger(String eventString) {
		val tokens = eventString.split("\\.")
		if (tokens.size < 1 || tokens.size > 3) {
			throw new IllegalArgumentException("Event descriptor " + eventString
				+ " does not contain exactly 1, 2 or 3 dot separated tokens."
			)
		}
		
		var gammaInterface = null as Interface
		var gammaPort = null as Port
		
		if (tokens.size == 1) {
			gammaInterface = getOrCreateDefaultInterface()
			gammaPort = getOrCreateDefaultPort()
		}
		else {
			val interfaceName = tokens.get(tokens.size - 2)
			gammaInterface = getOrTransformInterfaceByName(interfaceName)
			
			if (tokens.size >= 3) {
				val portName = tokens.head
				gammaPort = getOrTransformPortByName(gammaInterface, portName)
			}
			else {
				gammaPort = getOrTransformDefaultInterfacePort(gammaInterface)
			}
		}
		
		val eventName = tokens.last
		val gammaEvent = getOrTransformInEvent(gammaInterface, eventName)
		
		val gammaEventReference = createPortEventReference
		gammaEventReference.port = gammaPort
		gammaEventReference.event = gammaEvent
		
		val gammaEventTrigger = createEventTrigger
		gammaEventTrigger.eventReference = gammaEventReference
		return gammaEventTrigger
	}
	
}