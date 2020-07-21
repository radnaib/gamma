/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.uppaal.transformation

import hu.bme.mit.gamma.expression.model.AddExpression
import hu.bme.mit.gamma.expression.model.AndExpression
import hu.bme.mit.gamma.expression.model.ConstantDeclaration
import hu.bme.mit.gamma.expression.model.DivExpression
import hu.bme.mit.gamma.expression.model.DivideExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.FalseExpression
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression
import hu.bme.mit.gamma.expression.model.GreaterExpression
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.InequalityExpression
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.LessEqualExpression
import hu.bme.mit.gamma.expression.model.LessExpression
import hu.bme.mit.gamma.expression.model.ModExpression
import hu.bme.mit.gamma.expression.model.MultiplyExpression
import hu.bme.mit.gamma.expression.model.NotExpression
import hu.bme.mit.gamma.expression.model.OrExpression
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.SubtractExpression
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.expression.model.UnaryMinusExpression
import hu.bme.mit.gamma.expression.model.UnaryPlusExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.model.XorExpression
import hu.bme.mit.gamma.uppaal.util.MultiaryExpressionCreator
import hu.bme.mit.gamma.util.GammaEcoreUtil
import uppaal.expressions.ArithmeticOperator
import uppaal.expressions.CompareOperator
import uppaal.expressions.Expression
import uppaal.expressions.ExpressionsFactory
import uppaal.expressions.LogicalOperator

class ExpressionTransformer {
	
	protected final Traceability traceability
	//
	protected final extension MultiaryExpressionCreator multiaryExpressionCreator = MultiaryExpressionCreator.INSTANCE
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ExpressionsFactory expressionsFactory = ExpressionsFactory.eINSTANCE
	
	new(Traceability traceability) {
		this.traceability = traceability
	}
	
	def dispatch Expression transform(IntegerLiteralExpression expression) {
		return createLiteralExpression => [it.text = expression.value.toString]
	}
	
	def dispatch Expression transform(TrueExpression expression) {
		return createLiteralExpression => [it.text = true.toString]
	}
	
	def dispatch Expression transform(FalseExpression expression) {
		return createLiteralExpression => [it.text = false.toString]
	}
	
	def dispatch Expression transform(EnumerationLiteralExpression expression) {
		val index = expression.reference.index
		return createLiteralExpression => [
			it.text = index.toString
		]
	}
	
	def dispatch Expression transform(ReferenceExpression expression) {
		val xStsDeclaration = expression.declaration
		if (xStsDeclaration instanceof ConstantDeclaration) {
			return xStsDeclaration.expression.transform
		}
		val xStsVariable = xStsDeclaration as VariableDeclaration
		if (xStsVariable instanceof VariableDeclaration) {
			val uppaalVariable = traceability.get(xStsVariable)
			return createIdentifierExpression => [
				it.identifier = uppaalVariable.variable.head
			]
		}
		
	}
	
	def dispatch Expression transform(NotExpression expression) {
		return createNegationExpression => [
			it.negatedExpression = expression.operand.transform
		]
	}
	
	def dispatch Expression transform(OrExpression expression) {
		val uppaalOperands = newArrayList
		for (xStsOperand : expression.operands) {
			uppaalOperands += xStsOperand.transform
		}
		return LogicalOperator.OR.createLogicalExpression(uppaalOperands)
	}
	
	def dispatch Expression transform(XorExpression expression) {
		val uppaalOperands = newArrayList
		for (xStsOperand : expression.operands) {
			uppaalOperands += xStsOperand.transform
		}
		return LogicalOperator.XOR.createLogicalExpression(uppaalOperands)
	}
	
	def dispatch Expression transform(AndExpression expression) {
		val uppaalOperands = newArrayList
		for (xStsOperand : expression.operands) {
			uppaalOperands += xStsOperand.transform
		}
		return LogicalOperator.AND.createLogicalExpression(uppaalOperands)
	}
	
	def dispatch Expression transform(EqualityExpression expression) {
		return createCompareExpression => [
			it.firstExpr = expression.leftOperand.transform
			it.operator = CompareOperator.EQUAL
			it.secondExpr = expression.rightOperand.transform
		]
	}
	
	def dispatch Expression transform(InequalityExpression expression) {
		return createCompareExpression => [
			it.firstExpr = expression.leftOperand.transform
			it.operator = CompareOperator.UNEQUAL
			it.secondExpr = expression.rightOperand.transform
		]
	}
	
	def dispatch Expression transform(GreaterExpression expression) {
		return createCompareExpression => [
			it.firstExpr = expression.leftOperand.transform
			it.operator = CompareOperator.GREATER
			it.secondExpr = expression.rightOperand.transform
		]
	}
	
	def dispatch Expression transform(GreaterEqualExpression expression) {
		return createCompareExpression => [
			it.firstExpr = expression.leftOperand.transform
			it.operator = CompareOperator.GREATER_OR_EQUAL
			it.secondExpr = expression.rightOperand.transform
		]
	}
	
	def dispatch Expression transform(LessExpression expression) {
		return createCompareExpression => [
			it.firstExpr = expression.leftOperand.transform
			it.operator = CompareOperator.LESS
			it.secondExpr = expression.rightOperand.transform
		]
	}
	
	def dispatch Expression transform(LessEqualExpression expression) {
		return createCompareExpression => [
			it.firstExpr = expression.leftOperand.transform
			it.operator = CompareOperator.LESS_OR_EQUAL
			it.secondExpr = expression.rightOperand.transform
		]
	}
	
	def dispatch Expression transform(AddExpression expression) {
		val uppaalOperands = newArrayList
		for (xStsOperand : expression.operands) {
			uppaalOperands += xStsOperand.transform
		}
		return ArithmeticOperator.ADD.createArithmeticExpression(uppaalOperands)
	}
	
	def dispatch Expression transform(SubtractExpression expression) {
		return createArithmeticExpression => [
			it.firstExpr = expression.leftOperand.transform
			it.operator = ArithmeticOperator.SUBTRACT
			it.secondExpr = expression.rightOperand.transform
		]
	}
	
	def dispatch Expression transform(MultiplyExpression expression) {
		val uppaalOperands = newArrayList
		for (xStsOperand : expression.operands) {
			uppaalOperands += xStsOperand.transform
		}
		return ArithmeticOperator.MULTIPLICATE.createArithmeticExpression(uppaalOperands)
	}
	
	def dispatch Expression transform(DivideExpression expression) {
		return createArithmeticExpression => [
			it.firstExpr = expression.leftOperand.transform
			it.operator = ArithmeticOperator.DIVIDE // Same as Divide, UPPAAL does not support doubles
			it.secondExpr = expression.rightOperand.transform
		]
	}
	
	def dispatch Expression transform(DivExpression expression) {
		return createArithmeticExpression => [
			it.firstExpr = expression.leftOperand.transform
			it.operator = ArithmeticOperator.DIVIDE 
			it.secondExpr = expression.rightOperand.transform
		]
	}
	
	def dispatch Expression transform(ModExpression expression) {
		return createArithmeticExpression => [
			it.firstExpr = expression.leftOperand.transform
			it.operator = ArithmeticOperator.MODULO 
			it.secondExpr = expression.rightOperand.transform
		]
	}
	
	def dispatch Expression transform(UnaryPlusExpression expression) {
		return createPlusExpression => [
			it.confirmedExpression = expression.operand.transform
		]
	}
	
	def dispatch Expression transform(UnaryMinusExpression expression) {
		return createMinusExpression => [
			it.invertedExpression = expression.operand.transform
		]
	}
	
	def dispatch Expression transform(IfThenElseExpression expression) {
		return createConditionExpression => [
			it.ifExpression = expression.condition.transform
			it.thenExpression = expression.then.transform
			it.elseExpression = expression.^else.transform
		]
	}
	
}