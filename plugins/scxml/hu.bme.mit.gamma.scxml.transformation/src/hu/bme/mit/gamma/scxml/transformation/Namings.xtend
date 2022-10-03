package hu.bme.mit.gamma.scxml.transformation

import ac.soton.scxml.ScxmlFinalType
import ac.soton.scxml.ScxmlHistoryType
import ac.soton.scxml.ScxmlParallelType
import ac.soton.scxml.ScxmlScxmlType
import ac.soton.scxml.ScxmlStateType

class Namings {
	
	// TODO check default names differ from user defined interface and port names
	// at the end of the transformation
	def static String getDefaultPortName() '''_DefaultPort'''
	def static String getDefaultInterfaceName() '''_DefaultInterface'''
	def static String getDefaultInterfacePortName(String scxmlInterfaceName) '''«scxmlInterfaceName»_DefaultPort'''
	def static String getInterfaceName(String scxmlInterfaceName) '''«scxmlInterfaceName»'''
	def static String getPortName(String scxmlPortName) '''«scxmlPortName»'''
	
	def static String getInEventName(String scxmlEventName) '''in_«scxmlEventName»'''
	def static String getOutEventName(String scxmlEventName) '''out_«scxmlEventName»'''
	
	def static String getAdapterName(ScxmlScxmlType scxmlRoot) '''«scxmlRoot.name»Adapter'''
	def static String getInternalEventQueueName(ScxmlScxmlType scxmlRoot) '''«scxmlRoot.name»InternalEventQueue'''
	def static String getExternalEventQueueName(ScxmlScxmlType scxmlRoot) '''«scxmlRoot.name»ExternalEventQueue'''
	
	def static String getStatechartName(ScxmlScxmlType scxmlRoot) '''«scxmlRoot.name»'''
	def static String getRegionName(String scxmlElementName) '''«scxmlElementName»Region'''
	
	def static String getParallelName(ScxmlParallelType scxmlParallel) '''«scxmlParallel.id»'''
	def static String getStateName(ScxmlStateType scxmlState) '''«scxmlState.id»'''
	def static String getFinalName(ScxmlFinalType scxmlFinal) '''«scxmlFinal.id»'''
	
	def static String getInitialName(ScxmlStateType scxmlParentState) '''«scxmlParentState.id»Initial'''
	def static String getInitialName(ScxmlScxmlType scxmlRoot) '''«scxmlRoot.name»Initial'''
	def static String getShallowHistoryName(ScxmlHistoryType scxmlHistoryState) '''«scxmlHistoryState.id»ShallowHistory'''
	def static String getDeepHistoryName(ScxmlHistoryType scxmlHistoryState) '''«scxmlHistoryState.id»DeepHistory'''
	
}