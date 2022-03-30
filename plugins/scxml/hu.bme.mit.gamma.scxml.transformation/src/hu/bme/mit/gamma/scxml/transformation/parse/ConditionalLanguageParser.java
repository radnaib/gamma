package hu.bme.mit.gamma.scxml.transformation.parse;

import java.io.StringReader;
import java.util.Map;
import java.util.NoSuchElementException;

import org.eclipse.xtext.CrossReference;
import org.eclipse.xtext.nodemodel.INode;
import org.eclipse.xtext.parser.IParseResult;

import com.google.inject.Injector;

import hu.bme.mit.gamma.expression.language.ExpressionLanguageStandaloneSetup;
import hu.bme.mit.gamma.expression.language.parser.antlr.ExpressionLanguageParser;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.OpaqueExpression;

public class ConditionalLanguageParser {

	ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE;
	
	private Injector injector = new ExpressionLanguageStandaloneSetup().createInjectorAndDoEMFRegistration();

	public Expression parse(String expression, Map<String, Declaration> scope) {
		CustomLanguageParser parser = injector.getInstance(CustomLanguageParser.class);
		StringReader reader = new StringReader(expression);
		IParseResult result = parser.parse(reader);

		if (result.hasSyntaxErrors()) {
			return createOpaqueExpression(expression);
		}

		try {
			for (INode node : result.getRootNode().getLeafNodes()) {
				if (node.getGrammarElement() instanceof CrossReference) {
					final DirectReferenceExpression refExpr = (DirectReferenceExpression) node.getSemanticElement();

					Declaration decl = scope.get(node.getText());
					if (decl != null) {
						refExpr.setDeclaration(decl);
					} else {
						throw new NoSuchElementException();
					}
				}
			}
			return (Expression) result.getRootASTElement();
		} catch (NoSuchElementException e) {
		}

		return createOpaqueExpression(expression);
	}

	private Expression createOpaqueExpression(String expression) {
		OpaqueExpression opaqueExpression = expressionModelFactory.createOpaqueExpression();
		opaqueExpression.setExpression(expression);
		return opaqueExpression;
	}

}
