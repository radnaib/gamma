package hu.bme.mit.gamma.scxml.transformation

abstract class AtomicElementTransformer extends AbstractTransformer {
	
	protected final StatechartTraceability traceability
	
	new(StatechartTraceability traceability) {
		this.traceability = traceability
	}
}