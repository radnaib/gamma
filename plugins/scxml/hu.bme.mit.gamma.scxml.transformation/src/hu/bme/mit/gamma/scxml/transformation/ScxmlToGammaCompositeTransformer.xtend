/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scxml.transformation

import ac.soton.scxml.ScxmlDataType
import ac.soton.scxml.ScxmlInvokeType
import ac.soton.scxml.ScxmlScxmlType
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent
import hu.bme.mit.gamma.statechart.interface_.RealizationMode
import java.util.List
import org.eclipse.emf.common.util.URI

import static ac.soton.scxml.ScxmlModelDerivedFeatures.*
import static hu.bme.mit.gamma.scxml.transformation.Namings.*

// TODO Check features of both composite and atomic components.
// Transform these features for both kinds of statecharts.
class ScxmlToGammaCompositeTransformer extends CompositeElementTransformer {
	
	protected final extension PortTransformer portTransformer
	
	// Root element of the SCXML statechart model to transform
	protected final ScxmlScxmlType scxmlRoot
	protected final String fileURI
	
	// Contained <invoke> elements invoking SCXML substatecharts
	protected List<ScxmlInvokeType> invokes
	
	new(ScxmlScxmlType scxmlRoot, String fileURI) {
		this(scxmlRoot, new CompositeTraceability(scxmlRoot), fileURI)
	}
	
	new(ScxmlScxmlType scxmlRoot, CompositeTraceability traceability, String fileURI) {
		super(traceability)
		this.scxmlRoot = scxmlRoot
		this.fileURI = fileURI
		
		val portTraceability = traceability.createStatechartTraceability(scxmlRoot)
		this.portTransformer = new PortTransformer(portTraceability)
	}
	
	def execute() {
		val rootComponent = scxmlRoot.transform
		traceability.rootComponent = rootComponent as AsynchronousComponent
		
		return traceability
	}
	
	protected def AsynchronousComponent transform(ScxmlScxmlType scxmlRoot) {
		initQueueCapacity
		
		invokes = getAllInvokes(scxmlRoot)
		
		if (invokes.empty) {
			val statechartTraceability = traceability.createStatechartTraceability(scxmlRoot)
			traceability.putTraceability(fileURI, statechartTraceability)
			
			return scxmlRoot.transformAtomic
		}
		else {
			for (invoke : invokes) {
				var src = invoke.src	// TODO Check src | srcexpr
				
				if (!traceability.containsTraceability(src)) {
					val subcomponentRoot = loadSubcomponent(src)
					
					val newStatechartTraceability = traceability.createStatechartTraceability(subcomponentRoot)
					traceability.putTraceability(src, newStatechartTraceability)
					
					subcomponentRoot.transformAtomic
				}
			}
			
			return scxmlRoot.transformComposite
		}
	}
	
	private def initQueueCapacity() {
		// Define default queue capacity
		val queueCapacityDeclaration = createConstantDeclaration
		queueCapacityDeclaration.name = "QUEUE_CAPACITY"
		
		val capacity = expressionUtil.toIntegerLiteral(4)
		queueCapacityDeclaration.expression = capacity
		queueCapacityDeclaration.type = createIntegerTypeDefinition
		
		traceability.setQueueCapacity(queueCapacityDeclaration)
	}
	
	private def loadSubcomponent(String path) {
		val fileURI = URI.createPlatformResourceURI(path, true);
		val documentRoot = ecoreUtil.normalLoad(fileURI);
		val scxmlRoot = ecoreUtil.getFirstOfAllContentsOfType(documentRoot, ScxmlScxmlType);
		return scxmlRoot
	}
	
	protected def transformAtomic(ScxmlScxmlType scxmlRoot) {
		val statechartTraceability = traceability.getTraceability(scxmlRoot)
		
		val statechartTransformer = new ScxmlToGammaStatechartTransformer(scxmlRoot, statechartTraceability)
		statechartTransformer.execute
		
		return statechartTraceability.getAdapter
	}
	
	protected def transformComposite(ScxmlScxmlType scxmlRoot) {
		val gammaComposite = createScheduledAsynchronousCompositeComponent
		gammaComposite.name = getCompositeStatechartName(scxmlRoot)
		
		// Instantiate transformed invoked child statecharts
		for (invoke : invokes) {
			val statechartTraceability = traceability.getTraceability(invoke.src)
			
			// TODO Extend to deeper composition hierarchy levels later
			val gammaSubcomponentType = statechartTraceability.adapter as AsynchronousComponent
			
			val gammaSubcomponent = gammaSubcomponentType.instantiateAsynchronousComponent
			gammaSubcomponent.name = invoke.id
			gammaComposite.components += gammaSubcomponent
			
			traceability.putComponentInstance(invoke, gammaSubcomponent)
		}
		
		// Create ports, port bindings and channels in the composite component
		val datamodels = scxmlRoot.datamodel
		if (datamodels !== null) {
			val datamodel = datamodels.head
			if (datamodel !== null) {
				val dataElements = getDataElements(datamodel)
				
				// TODO Move string literal parts of names to Namings
				val portDataElements = dataElements.filter [ it |
					it.eContainer.eContainer instanceof ScxmlScxmlType && it.id.startsWith("pro_port_") ||
						it.id.startsWith("req_port_")
				]
				for (portData : portDataElements) {
					val gammaPort = portData.getOrCreatePort
					gammaComposite.ports += gammaPort
				}
				
				val bindingDataElements = dataElements.filter [ it |
					it.eContainer.eContainer instanceof ScxmlScxmlType && it.id.startsWith("binding_")
				]
				for (binding : bindingDataElements) {
					val gammaPortBinding = binding.createBinding
					gammaComposite.portBindings += gammaPortBinding
				}
				
				val channelDataElements = dataElements.filter [ it |
					it.eContainer.eContainer instanceof ScxmlScxmlType && it.id.startsWith("channel_")
				]
				for (channel : channelDataElements) {
					val gammaChannel = channel.createChannel
					gammaComposite.channels += gammaChannel
				}
			}
		}
		
		return gammaComposite
	}
	
	protected def getOrCreatePort(ScxmlDataType portData) {
		val isProvided = portData.id.startsWith("pro_port_")
		val realizationMode = isProvided ? RealizationMode.PROVIDED : RealizationMode.REQUIRED

		// Get port name and interface name from port descriptor string
		val portString = portData.expr.trim
		val tokens = portString.split("\\.")
		if (tokens.size < 1 || tokens.size > 2) {
			throw new IllegalArgumentException(
				"Port descriptor " + portString + " does not contain exactly 1 or 2 dot separated tokens."
			)
		}

		var scxmlInterfaceName = ""
		var scxmlPortName = ""

		if (tokens.size == 1) {
			scxmlInterfaceName = portString
			scxmlPortName = portString
		} else {
			scxmlInterfaceName = tokens.get(tokens.size - 1)
			scxmlPortName = tokens.head
		}
		//
		
		val gammaPort = portTransformer.getOrTransformPort(
			scxmlPortName,
			scxmlInterfaceName,
			realizationMode
		)
		
		traceability.putPort(scxmlPortName, gammaPort)
		
		return gammaPort
	}
	
	protected def createBinding(ScxmlDataType bindingData) {
		val bindingString = bindingData.expr.trim
		val tokens = bindingString.split("\\.|\\s*\\-\\s*")
		if (tokens.size != 3) {
			throw new IllegalArgumentException(
				"Binding descriptor " + bindingString + " does not contain exactly 3 dot separated tokens."
			)
		}
		
		val sourcePortName = tokens.get(0)
		val targetInstanceName = tokens.get(1)
		val targetPortName = tokens.get(2)
		
		//
		
		val gammaSourcePort = traceability.getPort(sourcePortName)
		val gammaInstancePortReference = createInstancePortReference(targetInstanceName, targetPortName)
		
		val gammaPortBinding = createPortBinding(gammaSourcePort, gammaInstancePortReference)
		return gammaPortBinding
	}
	
	protected def createChannel(ScxmlDataType channelData) {
		val channelString = channelData.expr.trim
		val tokens = channelString.split("\\.|\\s*\\-\\s*")
		if (tokens.size != 4) {
			throw new IllegalArgumentException(
				"Channel descriptor " + channelString + " does not contain exactly 4 dot separated tokens."
			)
		}
		
		val sourceInstanceName = tokens.get(0)
		val sourcePortName = tokens.get(1)
		val targetInstanceName = tokens.get(2)
		val targetPortName = tokens.get(3)
		
		//
		
		val sourceInstancePortReference = createInstancePortReference(sourceInstanceName, sourcePortName)
		val targetInstancePortReference = createInstancePortReference(targetInstanceName, targetPortName)
		
		val gammaChannel = createChannel(sourceInstancePortReference, targetInstancePortReference)
		return gammaChannel
	}
	
	private def createInstancePortReference(String instanceName, String scxmlPortName) {
		val instance = traceability.getComponentInstance(instanceName)
		
		// TODO Make it more performant to get statechart traceability
		// by instance invokeId or source URI.
		val statechartTraceability = traceability.getTraceabilityById(instanceName)
		val port = statechartTraceability.getPort(scxmlPortName)
		
		
		val instancePortReference = createInstancePortReference(instance, port)
		return instancePortReference
	}
}