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

import hu.bme.mit.gamma.statechart.interface_.Component

class ScxmlToGammaCompositeTransformer extends CompositeElementTransformer {

	// Root element of the SCXML statechart model to transform
	protected final String rootFileURI

	new(String rootFileURI) {
		this(new CompositeTraceability(rootFileURI), rootFileURI)
	}

	new(CompositeTraceability compositeTraceability, String rootFileURI) {
		super(compositeTraceability)
		this.rootFileURI = rootFileURI
	}

	// Entry point for the SCXML to Gamma hierarchical statechart transformation
	def execute() {
		val rootStatechartTraceability = compositeTraceability.createStatechartTraceability(rootFileURI)
		
		// Execute root statechart transformation.
		// The object rootStatechartTraceability is populated with data during transformation.
		val rootStatechartTransformer = new ScxmlToGammaStatechartTransformer(rootStatechartTraceability)
		rootStatechartTransformer.execute()

		return compositeTraceability
	}
}
