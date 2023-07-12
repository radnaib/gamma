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
package hu.bme.mit.gamma.xsts.nuxmv.transformation.serializer

import hu.bme.mit.gamma.expression.model.AndExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.FalseExpression
import hu.bme.mit.gamma.expression.model.ImplyExpression
import hu.bme.mit.gamma.expression.model.OrExpression
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.expression.model.XorExpression

class ExpressionSerializer extends hu.bme.mit.gamma.expression.util.ExpressionSerializer {
	// Singleton
	public static final ExpressionSerializer INSTANCE = new ExpressionSerializer
	protected new() {}
	//
	
	override String _serialize(EnumerationLiteralExpression expression) '''«expression.reference.name»'''
	
	override String serialize(Expression expression) {
		return super.serialize(expression)
	}
	
	override String _serialize(TrueExpression expression) '''TRUE'''

	override String _serialize(FalseExpression expression) '''FALSE'''
	
	override String _serialize(OrExpression expression) '''(«FOR operand : expression.operands SEPARATOR ' | '»«operand.serialize»«ENDFOR»)'''

	override String _serialize(XorExpression expression) '''(«FOR operand : expression.operands SEPARATOR ' xor '»«operand.serialize»«ENDFOR»)'''

	override String _serialize(AndExpression expression) '''(«FOR operand : expression.operands SEPARATOR ' & '»«operand.serialize»«ENDFOR»)'''

	override String _serialize(ImplyExpression expression) '''(«expression.leftOperand.serialize» -> «expression.rightOperand.serialize»)'''

	override String _serialize(EqualityExpression expression) '''(«expression.leftOperand.serialize» = «expression.rightOperand.serialize»)'''

}