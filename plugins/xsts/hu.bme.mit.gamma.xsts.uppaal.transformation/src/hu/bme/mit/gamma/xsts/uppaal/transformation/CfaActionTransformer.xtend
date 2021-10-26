package hu.bme.mit.gamma.xsts.uppaal.transformation

import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.uppaal.util.NtaBuilder
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.HavocAction
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Collection
import uppaal.declarations.VariableContainer
import uppaal.templates.Location
import uppaal.templates.LocationKind

import static hu.bme.mit.gamma.uppaal.util.XstsNamings.*

import static extension de.uni_paderborn.uppaal.derivedfeatures.UppaalModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import static extension java.lang.Math.*

class CfaActionTransformer {
	
	protected final extension NtaBuilder ntaBuilder
	protected final Traceability traceability
	protected final Collection<VariableContainer> transientVariables
	
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension VariableTransformer variableTransformer
	
	protected final extension HavocHandler havocHandler = HavocHandler.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	new (NtaBuilder ntaBuilder, Traceability traceability,
			Collection<VariableContainer> transientVariables) {
		this.ntaBuilder = ntaBuilder
		this.traceability = traceability
		this.transientVariables = transientVariables // No cloning, original reference must be used
		this.variableTransformer = new VariableTransformer(ntaBuilder, traceability)
		this.expressionTransformer = new ExpressionTransformer(traceability)
	}
	
	def dispatch Location transformAction(EmptyAction action, Location source) {
		return source
	}
	
	def dispatch Location transformAction(AssignmentAction action, Location source) {
		// UPPAAL does not support 'a = {1, 2, 5}' like assignments
		val assignmentActions = action.extractArrayLiteralAssignments
		var Location newSource = source
		for (assignmentAction : assignmentActions) {
			val uppaalLhs = assignmentAction.lhs.transform
			val uppaalRhs = assignmentAction.rhs.transform
			newSource = newSource.createUpdateEdge(nextCommittedLocationName,
					uppaalLhs, uppaalRhs)
		}
		return newSource
	}
	
	def dispatch Location transformAction(HavocAction action, Location source) {
		val xStsDeclaration = action.lhs.declaration
		val xStsVariable = xStsDeclaration as VariableDeclaration
		val uppaalVariable = traceability.get(xStsVariable)
		
		val selectionStruct = xStsVariable.createSelection
		val selection = selectionStruct.selection
		val guard = selectionStruct.guard
		
		if (selection === null) {
			return source // We do not do anything
		}
		
		// Optimization - the type of the variable can be set to this selection type
		val type = selection.typeDefinition.clone
		uppaalVariable.typeDefinition = type
		//
		
		val target = source.createUpdateEdge(nextCommittedLocationName,
				uppaalVariable, selection.createIdentifierExpression)
		val edge = target.incomingEdges.head
		edge.selection += selection
		if (guard !== null) {
			edge.addGuard(guard)
		}
		
		return target
	}
	
	def dispatch Location transformAction(VariableDeclarationAction action, Location source) {
		val xStsVariable = action.variableDeclaration
		val uppaalVariable = xStsVariable.transformAndTraceVariable
//		uppaalVariable.prefix = DataVariablePrefix.META // Does not work, see XSTS Crossroads
		uppaalVariable.extendNameWithHash // Needed for local declarations
		transientVariables += uppaalVariable
		val xStsInitialValue = xStsVariable.initialValue
		val uppaalRhs = xStsInitialValue?.transform
		return source.createUpdateEdge(nextCommittedLocationName, uppaalVariable, uppaalRhs)
	}
	
	protected def void extendNameWithHash(VariableContainer uppaalContainer) {
		for (uppaalVariable : uppaalContainer.variable) {
			uppaalVariable.name = '''«uppaalVariable.name»_«uppaalVariable.hashCode.abs»'''
		}
	}
	
	def dispatch Location transformAction(AssumeAction action, Location source) {
		val edge = source.createEdgeCommittedSource(nextCommittedLocationName)
		val uppaalExpression = action.assumption.transform
		edge.guard = uppaalExpression
		return edge.target
	}
	
	def dispatch Location transformAction(SequentialAction action, Location source) {
		val xStsActions = action.actions
		var actualSource = source
		for (xStsAction : xStsActions) {
			actualSource = xStsAction.transformAction(actualSource)
		}
		return actualSource
	}
	
	def dispatch Location transformAction(NonDeterministicAction action, Location source) {
		val xStsActions = action.actions
		val targets = newArrayList
		for (xStsAction : xStsActions) {
			targets += xStsAction.transformAction(source)
		}
		val parentTemplate = source.parentTemplate
		val target = parentTemplate.createLocation(LocationKind.COMMITED, nextCommittedLocationName)
		for (choiceTarget : targets) {
			choiceTarget.createEdge(target)
		}
		return target
	}
	
	def dispatch Location transformAction(IfAction action, Location source) {
		val clonedAction = action.clone
		val xStsConditions = clonedAction.conditions
		val xStsActions = clonedAction.branches
		
		// Tracing back to NonDeterministicAction transformation
		val proxy = xStsConditions.createChoiceActionWithExclusiveBranches(xStsActions)
		
		return proxy.transformAction(source)
	}
	
}