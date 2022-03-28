package hu.bme.mit.gamma.scxml.transformation

import ac.soton.scxml.ScxmlFinalType
import ac.soton.scxml.ScxmlParallelType
import ac.soton.scxml.ScxmlScxmlType
import ac.soton.scxml.ScxmlStateType

class Namings {
	
	def static String getStatechartName(ScxmlScxmlType scxmlRoot) '''«scxmlRoot.name»'''
	def static String getRegionName(String scxmlElementName) '''«scxmlElementName»Region'''
	def static String getParallelName(ScxmlParallelType scxmlParallel) '''«scxmlParallel.id»'''
	def static String getStateName(ScxmlStateType scxmlState) '''«scxmlState.id»'''
	def static String getFinalName(ScxmlFinalType scxmlFinal) '''«scxmlFinal.id»'''
	
}