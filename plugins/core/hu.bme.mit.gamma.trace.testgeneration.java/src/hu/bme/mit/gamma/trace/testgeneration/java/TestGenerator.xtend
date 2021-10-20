/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.trace.testgeneration.java

import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.statechart.composite.AbstractAsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.AsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.ExecutionTraceAllowedWaitingAnnotation
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration
import hu.bme.mit.gamma.trace.model.InstanceVariableState
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.testgeneration.java.util.TestGeneratorUtil
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.transformation.util.annotations.AnnotationNamings
import java.util.Collections
import java.util.List
import org.eclipse.emf.ecore.resource.ResourceSet

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.codegenerator.java.util.Namings.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class TestGenerator {
	// Constant strings
	protected final String BASE_PACKAGE
	protected final String TEST_FOLDER = "test-gen"
	protected final String TIMER_CLASS_NAME = "VirtualTimerService"
	protected final String TIMER_OBJECT_NAME = "timer"
	
	protected final String FINAL_TEST_PREFIX = "final"	
	protected final String TEST_ANNOTATION = "@Test"	
	protected final String TEST_NAME = "step"	
	protected final String ASSERT_TRUE = "assertTrue"	
	
	
	// Value is assigned by the execute methods
	protected final String PACKAGE_NAME
	protected final String CLASS_NAME
	protected final String TEST_CLASS_NAME
	protected final String TEST_INSTANCE_NAME
	
	// Resources
	
	protected final ResourceSet resourceSet
	
	protected final Package gammaPackage
	protected final Component component
	protected final List<ExecutionTrace> traces // Traces in OR logical relation
	protected final ExecutionTrace firstTrace
	protected final TestGeneratorUtil testGeneratorUtil
	protected final AbstractAllowedWaitingHandler waitingHandle 
	protected final ActAndAssertSerializer actAndAssertSerializer	
	
	// Auxiliary objects
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
	
	
	
	/**
	 * Note that the lists of traces represents a set of behaviors the component must conform to.
	 * Each trace must reference the same component with the same parameter values (arguments).
	 */
	new(List<ExecutionTrace> traces, String basePackage, String className) {
		this.firstTrace = traces.head
		this.component = firstTrace.component // Theoretically, the same thing what loadModels do
		this.resourceSet = component.eResource.resourceSet
		checkArgument(this.resourceSet !== null)
		this.gammaPackage = component.eContainer as Package
		this.BASE_PACKAGE = basePackage // For some reason, package platform URI does not work
		this.traces = traces
		// Initializing the string variables
		this.PACKAGE_NAME = getPackageName
    	this.CLASS_NAME = className
    	this.TEST_CLASS_NAME = component.reflectiveClassName
    	this.TEST_INSTANCE_NAME = TEST_CLASS_NAME.toFirstLower
    	
    	this.testGeneratorUtil = new TestGeneratorUtil(component)
		this.actAndAssertSerializer = new ActAndAssertSerializer(component, TEST_INSTANCE_NAME, TIMER_OBJECT_NAME)
		if (traces.flatMap[it.annotations].findFirst[it instanceof ExecutionTraceAllowedWaitingAnnotation] !== null) {
			this.waitingHandle = new WaitingAllowedInFunction(firstTrace,actAndAssertSerializer)
		} 
		else {
			this.waitingHandle = new DefaultWaitingAllowedHandler(firstTrace,actAndAssertSerializer)
		}
	}
	
	new(ExecutionTrace trace, String yakinduPackageName, String className) {
		this(Collections.singletonList(trace), yakinduPackageName, className)
	}
	
	/**
	 * Generates the test class.
	 */
	def String execute() {
		return traces.generateTestClass(component, CLASS_NAME).toString
	}
	
	def getPackageName() {
		val suffix = "view";
		var String finalName
		val name = gammaPackage.getName().toLowerCase();
		if (name.endsWith(suffix)) {
			finalName = name.substring(0, name.length() - suffix.length());
		}
		else {
			finalName = name;
		}
		return BASE_PACKAGE + "." + finalName
	}
	
	private def createPackageName() '''package «PACKAGE_NAME»;'''
		
	protected def generateTestClass(List<ExecutionTrace> traces, Component component, String className) '''
		«createPackageName»
		
		«component.generateImports»
		
		public class «className» {
			
			private static «TEST_CLASS_NAME» «TEST_INSTANCE_NAME»;
«««			Only if there are timing specis in the model
			«IF testGeneratorUtil.needTimer(component)»private static «TIMER_CLASS_NAME» «TIMER_OBJECT_NAME»;«ENDIF»
			
			@Before
			public void init() {
				«IF testGeneratorUtil.needTimer(component)»
«««					Only if there are timing specis in the model
					«TIMER_OBJECT_NAME» = new «TIMER_CLASS_NAME»();
					«TEST_INSTANCE_NAME» = new «TEST_CLASS_NAME»(«FOR parameter : firstTrace.arguments SEPARATOR ', ' AFTER ', '»«parameter.serialize»«ENDFOR»«TIMER_OBJECT_NAME»);  // Virtual timer is automatically set
				«ELSE»
«««				Each trace must reference the same component with the same parameter values (arguments)!
				«TEST_INSTANCE_NAME» = new «TEST_CLASS_NAME»(«FOR parameter : firstTrace.arguments SEPARATOR ', '»«parameter.serialize»«ENDFOR»);
			«ENDIF»
			}
			
			@After
			public void tearDown() {
				stop();
			}
			
			// Only for override by potential subclasses
			protected void stop() {
				«IF testGeneratorUtil.needTimer(component)»
					«TIMER_OBJECT_NAME» = null;
				«ENDIF»
				«TEST_INSTANCE_NAME» = null;				
			}
			
			«traces.generateTestCases»
			
			«IF waitingHandle instanceof WaitingAllowedInFunction»
				«generateWaitHandlerFunction()»
			«ENDIF»
		}
	'''
	
	protected def generateImports(Component component) '''
		import «BASE_PACKAGE».*;
		«FOR _package : firstTrace.typeDeclarations.map[it.containingPackage].toSet»
			import «_package.getPackageString(BASE_PACKAGE)».*;
		«ENDFOR»
		
		import static org.junit.Assert.«ASSERT_TRUE»;
		
		import org.junit.Before;
		import org.junit.After;
		import org.junit.Test;
	'''
	
	protected def CharSequence generateTestCases(List<ExecutionTrace> traces) {
		var stepId = 0
		var traceId = 0
		val builder = new StringBuilder
		// The traces are in an OR-relation
		builder.append('''
			«TEST_ANNOTATION»
			public void test() {
				«FOR trace : traces»
					«IF traces.last !== trace»try {«ENDIF»
					«traces.addTabIfNeeded(trace)»«FINAL_TEST_PREFIX»«TEST_NAME.toFirstUpper»«traceId++»();
					«traces.addTabIfNeeded(trace)»return;
					«IF traces.last !== trace»} catch(AssertionError e) {}«ENDIF»
				«ENDFOR»
			}
		''')
		traceId = 0
		// Parsing the remaining lines
		for (trace : traces) {
			val steps = newArrayList
			steps += trace.steps
			if (trace.cycle !== null) {
				// Cycle steps are not handled differently
				steps += trace.cycle.steps
			}
			for (step : steps) {
				
				val testMethod = '''
					public void «IF steps.indexOf(step) == steps.size - 1»«FINAL_TEST_PREFIX»«TEST_NAME.toFirstUpper»«traceId++»()«ELSE»«TEST_NAME + stepId++»()«ENDIF» {
						«IF step !== steps.head»«TEST_NAME»«IF step === steps.last»«stepId - 1»«ELSE»«stepId - 2»«ENDIF»();«ENDIF»
						// Act
						«FOR act : step.actions»
							«actAndAssertSerializer.serialize(act)»
						«ENDFOR»
						// Assert
						«IF !testGeneratorUtil.filterAsserts(step).nullOrEmpty»
							«waitingHandle.generateAssertBlock(testGeneratorUtil.filterAsserts(step))»
						«ENDIF»
					}
					
				'''
				builder.append(testMethod)
			}
		}
		return builder.toString
	}
	
	def generateWaitHandlerFunction() '''
		private void checkGeneralAsserts(String[] ports, String[] events, Object[][] objects) {
			boolean done = false;
			boolean wasPresent = true;
			int idx=0;
			 
			while(!done) {
				wasPresent = true;
				try {
					for(int i = 0; i<ports.length;i++) {
						assertTrue(«TEST_INSTANCE_NAME».isRaisedEvent(ports[i], events[i], objects[i]));
					}
					} catch (AssertionError error) {
					wasPresent= false;
					if(idx>1) {
						throw(error);
					}
				}
				if(wasPresent && idx>=0) {
					done=true;
				}
				else
				{
					«TEST_INSTANCE_NAME».schedule(null);
				}
				idx++;
			}
		}
	'''
	
	private def addTabIfNeeded(List<ExecutionTrace> traces, ExecutionTrace trace) '''«IF traces.last !== trace»	«ENDIF»'''
	

	

}