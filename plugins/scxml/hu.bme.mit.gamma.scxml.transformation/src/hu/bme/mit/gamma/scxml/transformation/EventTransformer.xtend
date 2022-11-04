package hu.bme.mit.gamma.scxml.transformation

import hu.bme.mit.gamma.statechart.interface_.EventDirection

import static hu.bme.mit.gamma.scxml.transformation.Namings.*
import hu.bme.mit.gamma.statechart.interface_.Interface

class EventTransformer extends AtomicElementTransformer {
	new(StatechartTraceability traceability) {
		super(traceability)
	}
	
	def getOrTransformInEvent(Interface gammaInterface, String eventName) {
		if (traceability.containsInEvent(gammaInterface -> eventName)) {
			return traceability.getInEvent(gammaInterface -> eventName)
		}
		else {
			return transformInEvent(gammaInterface, eventName)
		}
	}
	
	protected def transformInEvent(Interface gammaInterface, String eventName) {
		val gammaEvent = transformEvent(gammaInterface, EventDirection.IN, eventName)
		gammaEvent.name = getInEventName(eventName)
		traceability.putInEvent(gammaInterface -> eventName, gammaEvent)
		return gammaEvent
	}
	
	def getOrTransformOutEvent(Interface gammaInterface, String eventName) {
		if (traceability.containsOutEvent(gammaInterface -> eventName)) {
			return traceability.getOutEvent(gammaInterface -> eventName)
		}
		else {
			return transformOutEvent(gammaInterface, eventName)
		}
	}
	
	protected def transformOutEvent(Interface gammaInterface, String eventName) {
		val gammaEvent = transformEvent(gammaInterface, EventDirection.OUT, eventName)
		gammaEvent.name = getOutEventName(eventName)
		traceability.putOutEvent(gammaInterface -> eventName, gammaEvent)
		return gammaEvent
	}
	
	// This method assumes that the transformation of the interface
	// of the respective event has already happened when we transform the event.
	private def transformEvent(Interface gammaInterface, EventDirection direction, String eventName) {
		val gammaEvent = createEvent
		val gammaEventDeclaration = createEventDeclaration
		gammaEventDeclaration.event = gammaEvent
		gammaEventDeclaration.direction = direction
		
		gammaInterface.events += gammaEventDeclaration
		return gammaEvent
	}
	
}