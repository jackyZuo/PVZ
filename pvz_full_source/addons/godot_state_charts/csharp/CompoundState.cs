using System;
using Godot;

namespace GodotStateCharts;

public class CompoundState : StateChartState
{
	public new class SignalName : StateChartState.SignalName
	{
		public static readonly StringName ChildStateEntered = "child_state_entered";

		public static readonly StringName ChildStateExited = "child_state_exited";
	}

	public event Action ChildStateEntered
	{
		add
		{
			Wrapped.Connect(SignalName.ChildStateEntered, Callable.From(value));
		}
		remove
		{
			Wrapped.Disconnect(SignalName.ChildStateEntered, Callable.From(value));
		}
	}

	public event Action ChildStateExited
	{
		add
		{
			Wrapped.Connect(SignalName.ChildStateExited, Callable.From(value));
		}
		remove
		{
			Wrapped.Disconnect(SignalName.ChildStateExited, Callable.From(value));
		}
	}

	private CompoundState(Node wrapped)
		: base(wrapped)
	{
	}

	public new static CompoundState Of(Node state)
	{
		if (!(state.GetScript().As<Script>() is GDScript gDScript) || !gDScript.ResourcePath.EndsWith("compound_state.gd"))
		{
			throw new ArgumentException("Given node is not a compound state.");
		}
		return new CompoundState(state);
	}
}
