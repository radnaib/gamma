package hu.bme.mit.gamma.scxml.transformation

import hu.bme.mit.gamma.statechart.interface_.RealizationMode

import static com.google.common.base.Preconditions.checkState
import static hu.bme.mit.gamma.scxml.transformation.Namings.*

class PortTransformer extends AbstractTransformer {
	new(Traceability traceability) {
		super(traceability)
	}
	
	def getOrTransformPortByName(String portName) {
		checkState(portName !== null)
		if (traceability.containsPort(portName)) {
			return traceability.getPort(portName)
		}
		else {
			val gammaPort = transformPortByName(portName)
			return gammaPort
		}
	}
	
	// For now, different ports realize different interfaces.
	protected def transformPortByName(String portName) {
		val gammaInterface = createInterface
		val gammaInterfaceName = getInterfaceName(portName)
		gammaInterface.name = gammaInterfaceName
		traceability.putInterface(gammaInterfaceName, gammaInterface)
		
		val gammaInterfaceRealization = createInterfaceRealization
		gammaInterfaceRealization.realizationMode = RealizationMode.PROVIDED
		gammaInterfaceRealization.interface = gammaInterface
		
		val gammaPort = createPort
		gammaPort.name = getPortName(portName)
		gammaPort.interfaceRealization = gammaInterfaceRealization
		traceability.putPort(portName, gammaPort)
		
		return gammaPort
	}
	
}