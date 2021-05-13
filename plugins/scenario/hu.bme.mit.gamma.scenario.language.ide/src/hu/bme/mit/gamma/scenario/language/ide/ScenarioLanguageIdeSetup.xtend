/*
 * generated by Xtext 2.12.0
 */
package hu.bme.mit.gamma.scenario.language.ide

import com.google.inject.Guice
import hu.bme.mit.gamma.scenario.language.ScenarioLanguageRuntimeModule
import hu.bme.mit.gamma.scenario.language.ScenarioLanguageStandaloneSetup
import org.eclipse.xtext.util.Modules2

/**
 * Initialization support for running Xtext languages as language servers.
 */
class ScenarioLanguageIdeSetup extends ScenarioLanguageStandaloneSetup {

	override createInjector() {
		Guice.createInjector(Modules2.mixin(new ScenarioLanguageRuntimeModule, new ScenarioLanguageIdeModule))
	}
	
}
