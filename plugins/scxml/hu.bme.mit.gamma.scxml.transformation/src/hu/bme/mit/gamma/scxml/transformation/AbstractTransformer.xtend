package hu.bme.mit.gamma.scxml.transformation

import hu.bme.mit.gamma.scxml.transformation.parse.ConditionalLanguageParser
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.logging.Logger

abstract class AbstractTransformer {
	
	protected final Traceability traceability
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	
	protected final extension InterfaceModelFactory interfaceModelFactory = InterfaceModelFactory.eINSTANCE
	protected final extension StatechartModelFactory statechartModelFactory = StatechartModelFactory.eINSTANCE
	
	protected final ConditionalLanguageParser conditionalLanguageParser = new ConditionalLanguageParser()
	
	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	new(Traceability traceability) {
		this.traceability = traceability
	}
		
}