package hu.bme.mit.gamma.scxml.transformation

import ac.soton.scxml.ScxmlInvokeType
import ac.soton.scxml.ScxmlScxmlType
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent
import java.util.List
import org.eclipse.emf.common.util.URI

import static ac.soton.scxml.ScxmlModelDerivedFeatures.*
import static hu.bme.mit.gamma.scxml.transformation.Namings.*

class ScxmlToGammaCompositeTransformer extends CompositeElementTransformer {
	
	// Root element of the SCXML statechart model to transform
	protected final ScxmlScxmlType scxmlRoot
	
	// Contained <invoke> elements invoking SCXML substatecharts
	protected List<ScxmlInvokeType> invokes
	
	new(ScxmlScxmlType scxmlRoot) {
		this(scxmlRoot,
			new CompositeTraceability(scxmlRoot)
		)
	}
	
	new(ScxmlScxmlType scxmlRoot, CompositeTraceability traceability) {
		super(traceability)
		this.scxmlRoot = scxmlRoot
	}
	
	def execute() {
		val rootComponent = scxmlRoot.transform
		traceability.rootComponent = rootComponent as AsynchronousComponent
		
		return traceability
	}
	
	protected def AsynchronousComponent transform(ScxmlScxmlType scxmlRoot) {
		invokes = getAllInvokes(scxmlRoot)
		
		if (invokes.empty) {
			return scxmlRoot.transformAtomic
		}
		else {
			for (invoke : invokes) {
				var src = invoke.src
				
				// TODO Load and transform invoked statechart types only
				// when the composite traceability object does not contain the statechart.
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
			
			// TODO Extend to deeper composition hierarchy levels
			val gammaSubcomponentType = statechartTraceability.adapter as AsynchronousComponent
			
			val gammaSubcomponent = gammaSubcomponentType.instantiateAsynchronousComponent
			gammaComposite.components += gammaSubcomponent
			
			traceability.putComponentInstance(invoke, gammaSubcomponent)
		}
		
		return gammaComposite
	}
	
}