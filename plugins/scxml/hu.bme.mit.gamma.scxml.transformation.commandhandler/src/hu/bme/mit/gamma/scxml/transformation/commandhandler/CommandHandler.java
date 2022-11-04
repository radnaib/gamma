package hu.bme.mit.gamma.scxml.transformation.commandhandler;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.resources.IContainer;
import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.handlers.HandlerUtil;

import ac.soton.scxml.ScxmlScxmlType;
import hu.bme.mit.gamma.scxml.transformation.CompositeTraceability;
import hu.bme.mit.gamma.scxml.transformation.ScxmlToGammaCompositeTransformer;
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Interface;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.language.ui.serializer.StatechartLanguageSerializer;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;
import hu.bme.mit.gamma.util.FileUtil;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class CommandHandler extends AbstractHandler {
	
	protected final FileUtil fileUtil= FileUtil.INSTANCE;
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final StatechartUtil statechartUtil = StatechartUtil.INSTANCE;
	protected final Logger logger = Logger.getLogger("GammaLogger");

	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		try {
			ISelection sel = HandlerUtil.getActiveMenuSelection(event);
			if (sel instanceof IStructuredSelection) {
				IStructuredSelection selection = (IStructuredSelection) sel;
				Object firstElement = selection.getFirstElement();
				if (selection.size() == 1) {
					if (firstElement != null && firstElement instanceof IFile) {
						IFile file = (IFile) firstElement;
						IContainer parentFolder = file.getParent();
						String fileName = file.getName();
						String extensionlessFileName = fileUtil.getExtensionlessName(fileName);
						String parentPath = parentFolder.getFullPath().toString();
						String path = file.getFullPath().toString();
						URI fileURI = URI.createPlatformResourceURI(path, true);
						
						// Retrieve SCXML document root to transform
						EObject object = ecoreUtil.normalLoad(fileURI);
						ScxmlScxmlType scxmlRoot = ecoreUtil.getFirstOfAllContentsOfType(object, ScxmlScxmlType.class);
						
						// Model processing
						ScxmlToGammaCompositeTransformer compositeTransformer = new ScxmlToGammaCompositeTransformer(scxmlRoot);
						CompositeTraceability traceability = compositeTransformer.execute();
						
						// Interfaces and type declarations have to be explicitly serialized in another package
						List<Interface> gammaInterfaces = new ArrayList<Interface>(traceability.getInterfaces());
						Package gammaInterfacePackage = statechartUtil.wrapIntoPackage(gammaInterfaces.get(0));
						gammaInterfaces.remove(0);
						gammaInterfacePackage.getInterfaces().addAll(gammaInterfaces);
						
						// Pack and serialize asynchronous component
						AsynchronousComponent rootComponent = traceability.getRootComponent();
						Package gammaCompositePackage = statechartUtil.wrapIntoPackage(rootComponent);
						Collection<Component> components = traceability.getComponents();
						gammaCompositePackage.getComponents().addAll(components);
						gammaCompositePackage.getImports().addAll(
								StatechartModelDerivedFeatures.getImportablePackages(gammaCompositePackage));
						gammaCompositePackage.getImports().remove(gammaCompositePackage);
						
						StatechartLanguageSerializer packageSerializer = new StatechartLanguageSerializer();
						logger.log(Level.INFO, "Start serializing Gamma packages...");
						
						String declarationsPackageFileName = extensionlessFileName + "Declarations.gcd";
						packageSerializer.serialize(gammaInterfacePackage, parentPath, declarationsPackageFileName);
						//String compositePackageFileName = extensionlessFileName + ".gsm";
						//ecoreUtil.normalSave(gammaCompositePackage, parentPath, compositePackageFileName);
						String compositePackageFileName = extensionlessFileName + ".gcd";
						packageSerializer.serialize(gammaCompositePackage, parentPath, compositePackageFileName);
						
						logger.log(Level.INFO, "The SCXML - Gamma statechart transformation has finished.");
						
					}
				}
			}
		}
		catch (IOException e) {
				e.printStackTrace();
		}
		return null;
	}
	
}
