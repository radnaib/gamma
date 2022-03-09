package hu.bme.mit.gamma.scxml.transformation.parse;

import org.eclipse.xtext.parser.IParser;
import org.eclipse.xtext.scoping.IScopeProvider;
import org.eclipse.xtext.scoping.impl.AbstractDeclarativeScopeProvider;

import com.google.inject.Binder;
import com.google.inject.name.Names;

import hu.bme.mit.gamma.expression.language.ExpressionLanguageRuntimeModule;

public class CustomRuntimeModule extends ExpressionLanguageRuntimeModule {
	
	@Override
	public Class<? extends IParser> bindIParser() {
		return CustomLanguageParser.class;
	}
	
	@Override
	public void configureIScopeProviderDelegate(Binder binder) {
		binder.bind(IScopeProvider.class)
			.annotatedWith(Names.named(AbstractDeclarativeScopeProvider.NAMED_DELEGATE))
			.to(CustomLanguageScope.class);
	}
	
}
