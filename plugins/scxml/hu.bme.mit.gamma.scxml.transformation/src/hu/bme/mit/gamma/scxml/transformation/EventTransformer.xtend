package hu.bme.mit.gamma.scxml.transformation

import hu.bme.mit.gamma.statechart.interface_.EventDirection

import static hu.bme.mit.gamma.scxml.transformation.Namings.*
import hu.bme.mit.gamma.statechart.interface_.Port

class EventTransformer extends AbstractTransformer {
	new(Traceability traceability) {
		super(traceability)
	}
	
	def getOrTransformInEvent(Port gammaPort, String eventName) {
		if (traceability.containsInEvent(gammaPort -> eventName)) {
			return traceability.getInEvent(gammaPort -> eventName)
		}
		else {
			return transformInEvent(gammaPort, eventName)
		}
	}
	
	protected def transformInEvent(Port gammaPort, String eventName) {
		val gammaEvent = transformEvent(gammaPort, EventDirection.IN, eventName)
		gammaEvent.name = getInEventName(eventName)
		traceability.putInEvent(gammaPort -> eventName, gammaEvent)
		return gammaEvent
	}
	
	def getOrTransformOutEvent(Port gammaPort, String eventName) {
		if (traceability.containsOutEvent(gammaPort -> eventName)) {
			return traceability.getOutEvent(gammaPort -> eventName)
		}
		else {
			return transformOutEvent(gammaPort, eventName)
		}
	}
	
	protected def transformOutEvent(Port gammaPort, String eventName) {
		val gammaEvent = transformEvent(gammaPort, EventDirection.OUT, eventName)
		gammaEvent.name = getOutEventName(eventName)
		traceability.putOutEvent(gammaPort -> eventName, gammaEvent)
		return gammaEvent
	}
	
	// This method assumes that the transformation of the port and interface of the respecting event
	// has already happened when we transform the event.
	private def transformEvent(Port gammaPort, EventDirection direction, String eventName) {
		val gammaEvent = createEvent
		val gammaEventDeclaration = createEventDeclaration
		gammaEventDeclaration.event = gammaEvent
		gammaEventDeclaration.direction = direction
		
		val gammaInterface = gammaPort.interfaceRealization.interface
		gammaInterface.events += gammaEventDeclaration
		
		return gammaEvent
	}
	
}