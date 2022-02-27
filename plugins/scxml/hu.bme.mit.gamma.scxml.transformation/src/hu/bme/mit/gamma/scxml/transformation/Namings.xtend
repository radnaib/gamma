package hu.bme.mit.gamma.scxml.transformation

import ac.soton.scxml.ScxmlScxmlType
import ac.soton.scxml.ScxmlStateType

class Namings {
	
	def static String getStatechartDefinitionName(ScxmlScxmlType scxmlRoot) '''«scxmlRoot.name»'''
	def static String getStateName(ScxmlStateType state) '''«state.id»'''
	
}