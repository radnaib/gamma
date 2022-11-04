package hu.bme.mit.gamma.scxml.transformation

abstract class CompositeElementTransformer extends AbstractTransformer {
	
	protected final CompositeTraceability traceability
	
	new(CompositeTraceability traceability) {
		this.traceability = traceability
	}
}