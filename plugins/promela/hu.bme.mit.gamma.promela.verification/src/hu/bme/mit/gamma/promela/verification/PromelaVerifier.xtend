/********************************************************************************
 * Copyright (c) 2022-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.promela.verification

import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerifier
import java.io.BufferedWriter
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStreamWriter
import java.util.List
import java.util.Scanner

class PromelaVerifier extends AbstractVerifier {
	//
	protected extension LtlQueryAdapter queryAdapter = null // One needs to be created for every verification task
	// Save trace to file
	protected val SAVE_TRACE = false
	//
	
	override Result verifyQuery(Object traceability, String parameters, File modelFile, File queryFile) {
		val model = fileUtil.loadString(modelFile)
		val query = fileUtil.loadString(queryFile)

		var i = 0
		var Result result = null
		
		for (singleQuery : query.splitLines) {
			//
			queryAdapter = new LtlQueryAdapter
			// Supporting multiple queries in separate files
			val ltl = '''«System.lineSeparator»ltl ltl_«i» { «singleQuery.adaptQuery» }'''
			val modelWithLtl = model + ltl
			i++
			
			val rootGenFolder = new File(modelFile.parent, "." + fileUtil.getExtensionlessName(modelFile))
			rootGenFolder.mkdirs
			// Save model with all LTL
			val tmpGenFolder = new File(rootGenFolder + File.separator +
					fileUtil.getExtensionlessName(modelFile) + "-" + Thread.currentThread.name)
			tmpGenFolder.mkdirs
			
			// save model with LTL
			val fileWithLtl = new File(tmpGenFolder, fileUtil.getExtensionlessName(modelFile) + "-LTL.pml")
			fileWithLtl.deleteOnExit
			fileUtil.saveString(fileWithLtl, modelWithLtl)
			
			val newResult = verify(traceability, parameters, fileWithLtl)
			val oldTrace = result?.trace
			val newTrace = newResult?.trace
			if (oldTrace === null) {
				result = newResult
			}
			else if (newTrace !== null) {
				oldTrace.extend(newTrace)
				result = new Result(ThreeStateBoolean.UNDEF, oldTrace)
			}
			
			// Setting for deletion after the exe has been generated
			tmpGenFolder.forceDeleteOnExit
			rootGenFolder.forceDeleteOnExit
		}
		
		return result
	}
	
	private def Result verify(Object traceability, String parameters, File modelFile) {
		return this.verify(traceability, parameters, modelFile, new BmcData(true))
	}
	
	private def Result verify(Object traceability, String parameters, File modelFile,
			BmcData bmcData) {
		var Scanner resultReader = null
		try {
			// Directory where executing the command
			val execFolder = modelFile.parentFile
			
			// spin -search -a PromelaFile.pml
			val splitParameters = parameters.split("\\s+")
			val searchCommand = newArrayList("spin")
			searchCommand += splitParameters
			searchCommand += modelFile.name /* see exec wokr-dir */ 
			
			// trail file
			val trailFile = new File(modelFile.trailFile)
			trailFile.delete
			trailFile.deleteOnExit
			// pan file
			val panFile = new File(modelFile.panFile)
			panFile.delete
			panFile.deleteOnExit
			
			// save result of command
			val outputFile = new File(execFolder, ".output.txt")
			outputFile.deleteOnExit
			
			var isSearchDepthTooSmall = false
			var outOfMemory = false
			var needsAnotherIteration = false
			do {
				isSearchDepthTooSmall = false
				outOfMemory = false
				// Setting depth
				if (bmcData.doBmc) {
					bmcData.adjustSpinArgument(searchCommand)
				}
				// Executing the command
				logger.info("Executing command: " + searchCommand.join(" "))
				process = Runtime.getRuntime().exec(searchCommand, null, execFolder)
				val outputStream = process.inputStream
				// Reading the result of the command
				resultReader = new Scanner(outputStream)
				
				val outputString = new StringBuilder
				var String firstLine = null // Result checking
				
				while (resultReader.hasNext) {
					val line = resultReader.nextLine
					outputString.append(line + System.lineSeparator)
					
					if (firstLine === null) {
						val SEARCH_DEPTH_TOO_SMALL_STRING = "error: max search depth too small"
						val OUT_OF_MEMORY_STRING = "out of memory"
						if (line.contains(SEARCH_DEPTH_TOO_SMALL_STRING)) {
							isSearchDepthTooSmall = true
						}
						if (line.contains(OUT_OF_MEMORY_STRING)) {
							outOfMemory = true
						}
						if (!line.contains(SEARCH_DEPTH_TOO_SMALL_STRING) &&
								!line.contains("Depth=") &&
								!line.contains("resizing hashtable to")) {
							firstLine = line
						}
					}
				}
				fileUtil.saveString(outputFile, outputString.toString)
				
				if (firstLine.contains("violated") || firstLine.contains("acceptance cycle")) {
					super.result = ThreeStateBoolean.FALSE
				}
				else if (outOfMemory || isSearchDepthTooSmall) {
					super.result = ThreeStateBoolean.UNDEF
				}
				else {
					super.result = ThreeStateBoolean.TRUE
				}
				
				// BMC-related operations
				needsAnotherIteration = bmcData.doBmc && super.result == ThreeStateBoolean.UNDEF &&
						isSearchDepthTooSmall && !outOfMemory
				if (needsAnotherIteration) {
					bmcData.increaseDepth
					logger.info('''Max search depth is too small. Increasing it to «bmcData.depth»''')
				}
			} while (needsAnotherIteration)
			
			// Adapting result
			super.result = super.result.adaptResult
			
			if (!trailFile.exists) {
				// No proof/counterexample
				return new Result(result, null)
			}
			
			// spin -t -p -g -l -w PromelaFile.pml
			val traceCommand = #["spin", "-t", "-p", "-g", /*"-l",*/ "-w", modelFile.name /* see exec wokr-dir */]
			
			// Never claim file
			val nvrFile = new File(execFolder, "_spin_nvr.tmp")
			nvrFile.delete
			nvrFile.deleteOnExit
			
			// Executing the trace command
			logger.info("Executing command: " + traceCommand.join(" "))
			process = Runtime.getRuntime().exec(traceCommand, null, execFolder)
			
			val traceOutputStream = process.inputStream
			// Reading the result of the command
			resultReader = new Scanner(traceOutputStream)
			
			// save trace
			if (SAVE_TRACE) {
				// Trace file
				val traceFile = new File(modelFile.traceFile)
				traceFile.delete
				traceFile.deleteOnExit
				
				val fos = new FileOutputStream(traceFile)
				val bw = new BufferedWriter(new OutputStreamWriter(fos))
				
				while (resultReader.hasNext) {
					bw.write(resultReader.nextLine)
					bw.write(System.lineSeparator)
				}
				bw.close
				
				resultReader = new Scanner(traceFile)
			}
			
			val gammaPackage = traceability as Package
			val backAnnotator = new TraceBackAnnotator(gammaPackage, resultReader)
			val trace = backAnnotator.synchronizeAndExecute
			
			return new Result(result, trace)
		} finally {
			resultReader?.close
			cancel
		}
	}
	
	override cancel() {
		super.cancel
	}
	
	def getTrailFile(File modelFile) {
		return modelFile.parent + File.separator + modelFile.name + ".trail"
	}
	
	def getTraceFile(File modelFile) {
		return modelFile.parent + File.separator + modelFile.name + ".pmltrace"
	}
	
	def getPanFile(File modelFile) {
		return modelFile.parent + File.separator + "pan"
	}
	
	//
	
	static class BmcData {
		
		final String DEPTH_ARGUMENT = "m"
		
		boolean doBmc
		int depth
		double factor
		
		new() {
			this(false)
		}
		
		new(boolean doBmc) {
			this(doBmc, 1200, 1.5)
		}
		
		new(int depth, double factor) {
			this(true, depth, factor)
		}
		
		new(boolean doBmc, int depth, double factor) {
			this.doBmc = doBmc
			this.depth = depth
			this.factor = factor
		}
		
		def doBmc() {
			return this.doBmc
		}
		
		def adjustSpinArgument(List<String> searchCommand) {
			val depthArgument = searchCommand.findFirst[it.matches("-" + DEPTH_ARGUMENT + "[0-9]+")]
			val i = searchCommand.indexOf(depthArgument)
			searchCommand.set(i, '''-«DEPTH_ARGUMENT»«depth»''')
		}
		
		def increaseDepth() {
			depth = (depth * factor) as int
		}
		
		def getDepth() {
			return depth
		}
		
	}
	
	//
	
}