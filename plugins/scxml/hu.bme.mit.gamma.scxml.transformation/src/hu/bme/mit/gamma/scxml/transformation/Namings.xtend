package hu.bme.mit.gamma.scxml.transformation

import ac.soton.scxml.ScxmlFinalType
import ac.soton.scxml.ScxmlHistoryType
import ac.soton.scxml.ScxmlParallelType
import ac.soton.scxml.ScxmlScxmlType
import ac.soton.scxml.ScxmlStateType

class Namings {
	
	def static String getInterfaceName(String scxmlPortName) '''«scxmlPortName»_Interface'''
	def static String getPortName(String scxmlPortName) '''«scxmlPortName»'''
	def static String getInEventName(String scxmlEventName) '''in_«scxmlEventName»'''
	def static String getOutEventName(String scxmlEventName) '''out_«scxmlEventName»'''
	
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