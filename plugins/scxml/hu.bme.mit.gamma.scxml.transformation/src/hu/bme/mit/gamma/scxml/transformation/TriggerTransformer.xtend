package hu.bme.mit.gamma.scxml.transformation

import hu.bme.mit.gamma.statechart.interface_.EventDirection

class TriggerTransformer extends AbstractTransformer {
	
	protected final extension PortTransformer portTransformer
	protected final extension EventTransformer eventTransformer
	
	new(Traceability traceability) {
		super(traceability)
		this.portTransformer = new PortTransformer(traceability)
		this.eventTransformer = new EventTransformer(traceability)
	}
	
	def transformTrigger(String eventString) {
		val tokens = eventString.split("\\.")
		if (tokens.size < 1 || tokens.size > 3) {
			throw new IllegalArgumentException("Event descriptor " + eventString
				+ " does not contain exactly 1, 2 or 3 dot separated tokens."
			)
		}
		
		val defaultPort = traceability.defaultPort
		val gammaPort = (
			if (tokens.size == 2) {
				val portName = tokens.head
				val newGammaPort = getOrTransformPortByName(portName)
				newGammaPort
			}
			else {
				defaultPort
			}
		)
		
		val eventName = tokens.last
		val gammaEvent = getOrTransformInEvent(gammaPort, eventName)
		
		val gammaEventReference = createPortEventReference
		gammaEventReference.port = gammaPort
		gammaEventReference.event = gammaEvent
		
		val gammaEventTrigger = createEventTrigger
		gammaEventTrigger.eventReference = gammaEventReference
		return gammaEventTrigger
	}
	
}