package hu.bme.mit.gamma.scxml.transformation;

import ac.soton.scxml.ScxmlScxmlType;
import hu.bme.mit.gamma.statechart.statechart.SynchronousStatechartDefinition;
import org.eclipse.xtext.xbase.lib.ObjectExtensions;
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1;

@SuppressWarnings("all")
public class ScxmlToGammaStatechartTransformer extends AbstractTransformer {
  protected final ScxmlScxmlType scxmlRoot;
  
  protected final SynchronousStatechartDefinition gammaStatechart;
  
  public ScxmlToGammaStatechartTransformer(final ScxmlScxmlType scxmlRoot) {
    this(scxmlRoot, 
      new Traceability(scxmlRoot));
  }
  
  public ScxmlToGammaStatechartTransformer(final ScxmlScxmlType scxmlRoot, final Traceability traceability) {
    super(traceability);
    this.scxmlRoot = scxmlRoot;
    SynchronousStatechartDefinition _createSynchronousStatechartDefinition = this.statechartModelFactory.createSynchronousStatechartDefinition();
    final Procedure1<SynchronousStatechartDefinition> _function = (SynchronousStatechartDefinition it) -> {
      it.setName(scxmlRoot.getName());
    };
    SynchronousStatechartDefinition _doubleArrow = ObjectExtensions.<SynchronousStatechartDefinition>operator_doubleArrow(_createSynchronousStatechartDefinition, _function);
    this.gammaStatechart = _doubleArrow;
  }
  
  public Traceability execute() {
    this.traceability.put(this.scxmlRoot, this.gammaStatechart);
    return this.traceability;
  }
}
