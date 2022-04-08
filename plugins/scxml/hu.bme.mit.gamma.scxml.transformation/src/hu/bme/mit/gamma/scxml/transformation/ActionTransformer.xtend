package hu.bme.mit.gamma.scxml.transformation

import ac.soton.scxml.ScxmlAssignType
import ac.soton.scxml.ScxmlIfType
import ac.soton.scxml.ScxmlOnentryType
import ac.soton.scxml.ScxmlOnexitType
import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import java.util.logging.Level
import org.eclipse.emf.ecore.EObject

class ActionTransformer extends AbstractTransformer {
	
	protected final extension ScxmlGammaExpressionTransformer expressionTransformer
	
	new(Traceability traceability) {
		super(traceability)
		
		this.expressionTransformer = new ScxmlGammaExpressionTransformer(traceability)
	}
	
	def Action transform(ScxmlOnentryType scxmlOnentry) {
		logger.log(Level.INFO, "Transforming <onentry> element (" + scxmlOnentry + ")")
		
		// TODO Get list of all children actions, not just <assign>-s
		val scxmlActions = scxmlOnentry.assign
		val gammaEntryAction = scxmlActions.transformBlock;	// TODO
		
		return gammaEntryAction
	}
	
	def Action transform(ScxmlOnexitType scxmlOnexit) {
		logger.log(Level.INFO, "Transforming <onexit> element (" + scxmlOnexit + ")")
		
		// TODO Get list of all children actions, not just <assign>-s
		val scxmlActions = scxmlOnexit.assign
		val gammaExitAction = scxmlActions.transformBlock;	// TODO
		
		return gammaExitAction
	}
	
	def dispatch Action transformAction(ScxmlAssignType scxmlAssign) {
		logger.log(Level.INFO, "Transforming <assign> element (" + scxmlAssign + ")")
		
		val varLoc = scxmlAssign.location
		val variable = traceability.getVariable(varLoc)
		
		val expr = scxmlAssign.expr
		if (expr !== null) {
			val expression = expressionLanguageParser.parse(expr, traceability.variables)
			val gammaAssign = actionUtil.createAssignment(variable as VariableDeclaration, expression)
			return gammaAssign
		}
		
		// TODO Assignment by child content if expr is not present
		val gammaAssign = createEmptyStatement
		
		return gammaAssign
	}
	
	def dispatch Action transformAction(ScxmlIfType scxmlIf) {
		logger.log(Level.INFO, "Transforming <if> element (" + scxmlIf + ")")
		
		// TODO
		val gammaIf = createEmptyStatement
		
		return gammaIf
	}
	
	def Action transformBlock(Iterable<? extends EObject> actions) {
		if (actions.empty) {
			return createBlock
		}
		
		val gammaActions = actions.map[it.transformAction].toList
		val gammaBlock = actionUtil.wrap(gammaActions)
		
		return gammaBlock
	}
	
}