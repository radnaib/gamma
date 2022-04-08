package hu.bme.mit.gamma.scxml.transformation

import ac.soton.scxml.ScxmlDataType
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import java.util.logging.Level

class DataTransformer extends AbstractTransformer {
	
	new(Traceability traceability) {
		super(traceability)
	}
	
	def VariableDeclaration transform(ScxmlDataType scxmlData) {
		logger.log(Level.INFO, "Transforming <data> element (" + scxmlData + ")")
		
		val id = scxmlData.id
		val expr = scxmlData.expr
		val expression = expressionLanguageParser.parse(expr, traceability.variables)
		val type = expressionTypeDeterminator.getType(expression)
		
		val gammaDeclaration = expressionUtil.createVariableDeclaration(type, id, expression);
		
		traceability.put(scxmlData, gammaDeclaration)
		
		return gammaDeclaration
	}
	
}