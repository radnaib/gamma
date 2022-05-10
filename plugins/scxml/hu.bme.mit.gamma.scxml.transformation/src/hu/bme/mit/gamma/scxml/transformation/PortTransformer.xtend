package hu.bme.mit.gamma.scxml.transformation

import hu.bme.mit.gamma.statechart.interface_.RealizationMode

import static com.google.common.base.Preconditions.checkState
import static hu.bme.mit.gamma.scxml.transformation.Namings.*
import hu.bme.mit.gamma.statechart.interface_.Interface

class PortTransformer extends AbstractTransformer {
	new(Traceability traceability) {
		super(traceability)
	}
	
	def getOrCreateDefaultPort() {
		val defaultPort = traceability.getDefaultPort
		if (defaultPort !== null) {
			return defaultPort
		}
		else {
			val gammaPort = createDefaultPort
			traceability.setDefaultPort(gammaPort)
			return gammaPort
		}
	}
	
	// We assume that the statechart's default interface already exists at this point.
	protected def createDefaultPort() {
		val defaultInterface = traceability.getDefaultInterface
			
		val defaultInterfaceRealization = createInterfaceRealization
		defaultInterfaceRealization.realizationMode = RealizationMode.PROVIDED
		defaultInterfaceRealization.interface = defaultInterface
			
		val defaultPort = createPort
		defaultPort.name = getDefaultPortName
		defaultPort.interfaceRealization = defaultInterfaceRealization
		
		return defaultPort
	}
	
	def getOrTransformDefaultInterfacePort(Interface gammaInterface) {
		checkState(gammaInterface !== null)
		if (traceability.containsDefaultInterfacePort(gammaInterface)) {
			return traceability.getDefaultInterfacePort(gammaInterface)
		}
		else {
			val gammaPort = transformDefaultInterfacePort(gammaInterface)
			traceability.putDefaultInterfacePort(gammaInterface, gammaPort)
			return gammaPort
		}
	}
	
	// For now, all ports realize their interfaces in provided mode.
	protected def transformDefaultInterfacePort(Interface gammaInterface) {		
		val gammaInterfaceRealization = createInterfaceRealization
		gammaInterfaceRealization.realizationMode = RealizationMode.PROVIDED
		gammaInterfaceRealization.interface = gammaInterface
		
		val gammaPort = createPort
		val gammaInterfaceName = gammaInterface.name
		gammaPort.name = getDefaultInterfacePortName(gammaInterfaceName)
		gammaPort.interfaceRealization = gammaInterfaceRealization
		
		return gammaPort
	}
	
	def getOrTransformPortByName(Interface gammaInterface, String portName) {
		checkState(gammaInterface !== null)
		checkState(portName !== null)
		if (traceability.containsPort(portName)) {
			return traceability.getPort(portName)
		}
		else {
			val gammaPort = transformPortByName(gammaInterface, portName)
			traceability.putPort(portName, gammaPort)
			return gammaPort
		}
	}
	
	// For now, all ports realize their interfaces in provided mode.
	protected def transformPortByName(Interface gammaInterface, String portName) {		
		val gammaInterfaceRealization = createInterfaceRealization
		gammaInterfaceRealization.realizationMode = RealizationMode.PROVIDED
		gammaInterfaceRealization.interface = gammaInterface
		
		val gammaPort = createPort
		gammaPort.name = getPortName(portName)
		gammaPort.interfaceRealization = gammaInterfaceRealization
		
		return gammaPort
	}
	
}