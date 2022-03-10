package hu.bme.mit.gamma.scenario.model.derivedfeatures;

import java.util.List;
import java.util.stream.Collectors;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.scenario.model.Delay;
import hu.bme.mit.gamma.scenario.model.InteractionDefinition;
import hu.bme.mit.gamma.scenario.model.InteractionDirection;
import hu.bme.mit.gamma.scenario.model.ModalInteractionSet;
import hu.bme.mit.gamma.scenario.model.ModalityType;
import hu.bme.mit.gamma.scenario.model.NegatedModalInteraction;
import hu.bme.mit.gamma.scenario.model.Signal;

public class ScenarioModelDerivedFeatures extends ExpressionModelDerivedFeatures {
	
	public static final ScenarioModelDerivedFeatures INSTANCE = new ScenarioModelDerivedFeatures();

	protected ScenarioModelDerivedFeatures() {
	}

	public InteractionDirection getDirection(ModalInteractionSet set) {
		boolean isSend = false;
		List<InteractionDirection> directions = javaUtil.filterIntoList(set.getModalInteractions(), Signal.class).stream()
				.map(it -> it.getDirection()).collect(Collectors.toList());
		List<NegatedModalInteraction> negatedInteractions = javaUtil.filterIntoList(set.getModalInteractions(), NegatedModalInteraction.class);
		directions.addAll(negatedInteractions.stream()
				.filter(it -> it.getModalinteraction() instanceof Signal)
				.map(it -> ((Signal) it.getModalinteraction()).getDirection())
				.collect(Collectors.toList()));
		if (!directions.isEmpty()) {
			isSend = directions.stream().allMatch(it -> it.equals(InteractionDirection.SEND));
		}
		if (isSend) {
			return InteractionDirection.SEND;
		} else {
			return InteractionDirection.RECEIVE;
		}
	}

	public ModalityType getModality(ModalInteractionSet set) {
		List<Signal> signals = javaUtil.filterIntoList(set.getModalInteractions(), Signal.class);

		if (!signals.isEmpty()) {
			return signals.get(0).getModality();
		}
		List<InteractionDefinition> negatedSignal = javaUtil.filterIntoList(set.getModalInteractions(), NegatedModalInteraction.class).stream()
				.map(it -> it.getModalinteraction())
				.collect(Collectors.toList());
		if (!negatedSignal.isEmpty()) {
			InteractionDefinition interactionDefinition = negatedSignal.get(0);
			if (interactionDefinition instanceof Signal) {
				Signal signal = (Signal) interactionDefinition;
				return signal.getModality();
			}
		}
		
		List<Delay> delays = javaUtil.filterIntoList(set.getModalInteractions(),Delay.class);
		if (!delays.isEmpty()) {
			return delays.get(0).getModality();
		}
		return ModalityType.COLD;
	}
	
	public boolean isAllInteractionsOrBlockNegated(ModalInteractionSet set) {
		for (InteractionDefinition modalInteraction : set.getModalInteractions()){
			if (!(modalInteraction instanceof NegatedModalInteraction)) {
				return false;
			}			
		}
		return true;
	}
	
	public ModalityType getModality(InteractionDefinition i) {
		if (i instanceof Signal) {
			return ((Signal) i).getModality();
		}
		if (i instanceof Delay) {
			return ((Delay) i).getModality();
		}
		if (i instanceof NegatedModalInteraction) {
			NegatedModalInteraction negated = (NegatedModalInteraction)i;
			if (negated.getModalinteraction() instanceof Signal) {
				return getModality(negated.getModalinteraction());
			}
		}
		return null;
	}
	
	public InteractionDirection getDirection(InteractionDefinition i) {
		if (i instanceof Signal) {
			return ((Signal) i).getDirection();
		}
		if (i instanceof Delay) {
			return InteractionDirection.RECEIVE;
		}
		if (i instanceof NegatedModalInteraction) {
			NegatedModalInteraction negated = (NegatedModalInteraction)i;
			if (negated.getModalinteraction() instanceof Signal) {
				return getDirection(negated.getModalinteraction());
			}
		}
		return null;
	}
}
