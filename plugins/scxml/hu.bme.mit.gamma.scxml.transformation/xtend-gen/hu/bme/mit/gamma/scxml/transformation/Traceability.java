package hu.bme.mit.gamma.scxml.transformation;

import ac.soton.scxml.ScxmlScxmlType;
import ac.soton.scxml.ScxmlStateType;
import com.google.common.base.Preconditions;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.statechart.SynchronousStatechartDefinition;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import java.util.Map;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;
import org.eclipse.xtext.xbase.lib.Extension;
import org.eclipse.xtext.xbase.lib.Pair;

@SuppressWarnings("all")
public class Traceability {
  protected final ScxmlScxmlType scxmlRoot;
  
  protected final Map<ScxmlScxmlType, SynchronousStatechartDefinition> statechartDefinitions = CollectionLiterals.<ScxmlScxmlType, SynchronousStatechartDefinition>newHashMap();
  
  protected final Map<ScxmlStateType, State> states = CollectionLiterals.<ScxmlStateType, State>newHashMap();
  
  @Extension
  protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
  
  public Traceability(final ScxmlScxmlType scxmlRoot) {
    this.scxmlRoot = scxmlRoot;
  }
  
  public ScxmlScxmlType getScxmlRoot() {
    return this.scxmlRoot;
  }
  
  public SynchronousStatechartDefinition put(final ScxmlScxmlType scxmlRoot, final SynchronousStatechartDefinition gammaStatechart) {
    SynchronousStatechartDefinition _xblockexpression = null;
    {
      Preconditions.<ScxmlScxmlType>checkNotNull(scxmlRoot);
      Preconditions.<SynchronousStatechartDefinition>checkNotNull(gammaStatechart);
      Pair<ScxmlScxmlType, SynchronousStatechartDefinition> _mappedTo = Pair.<ScxmlScxmlType, SynchronousStatechartDefinition>of(scxmlRoot, gammaStatechart);
      _xblockexpression = this.statechartDefinitions.put(_mappedTo.getKey(), _mappedTo.getValue());
    }
    return _xblockexpression;
  }
  
  public SynchronousStatechartDefinition getStatechartDefinition(final ScxmlScxmlType scxmlRoot) {
    Preconditions.<ScxmlScxmlType>checkNotNull(scxmlRoot);
    final SynchronousStatechartDefinition gammaStatechart = this.statechartDefinitions.get(scxmlRoot);
    Preconditions.<SynchronousStatechartDefinition>checkNotNull(gammaStatechart);
    return gammaStatechart;
  }
}
