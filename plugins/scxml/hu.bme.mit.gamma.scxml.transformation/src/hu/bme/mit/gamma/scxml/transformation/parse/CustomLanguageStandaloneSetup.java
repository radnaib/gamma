package hu.bme.mit.gamma.scxml.transformation.parse;

import com.google.inject.Guice;
import com.google.inject.Injector;

import hu.bme.mit.gamma.expression.language.ExpressionLanguageStandaloneSetup;

public class CustomLanguageStandaloneSetup extends ExpressionLanguageStandaloneSetup {
	
	@Override
	public Injector createInjector() {
		return Guice.createInjector(new CustomRuntimeModule());
	}
	
}
