package hu.bme.mit.gamma.scxml.transformation

import ac.soton.scxml.ScxmlScxmlType

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension ac.soton.scxml.ScxmlModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.scxml.transformation.Namings.*
import hu.bme.mit.gamma.statechart.statechart.SynchronousStatechartDefinition

class ScxmlToGammaStatechartTransformer extends AbstractTransformer {
	
	// Root element of the SCXML statechart model to transform
	protected final ScxmlScxmlType scxmlRoot
	
	// Root element of the Gamma statechart definition as the transformation result
	protected final SynchronousStatechartDefinition gammaStatechart
	
	new(ScxmlScxmlType scxmlRoot) {
		this(scxmlRoot,
			new Traceability(scxmlRoot)
		)
	}
	
	new(ScxmlScxmlType scxmlRoot, Traceability traceability) {
		super(traceability)
		
		this.scxmlRoot = scxmlRoot
		this.gammaStatechart = createSynchronousStatechartDefinition => [
			it.name = scxmlRoot.name
		]
	}
	
	def execute() {
		traceability.put(scxmlRoot, gammaStatechart)
		
		//
		
		return traceability
	}
	
}