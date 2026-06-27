using System;
using Godot;

namespace GodotStateCharts;

public class Transition : NodeWrapper
{
	public class SignalName : Node.SignalName
	{
		public static readonly StringName Taken = "taken";
	}

	public class MethodName : Node.MethodName
	{
		public static readonly StringName Take = "take";
	}

	public event Action Taken
	{
		add
		{
			Wrapped.Connect(SignalName.Taken, Callable.From(value));
		}
		remove
		{
			Wrapped.Disconnect(SignalName.Taken, Callable.From(value));
		}
	}

	private Transition(Node transition)
		: base(transition)
	{
	}

	public static Transition Of(Node transition)
	{
		if (!(transition.GetScript().As<Script>() is GDScript gDScript) || !gDScript.ResourcePath.EndsWith("transition.gd"))
		{
			throw new ArgumentException("Given node is not a transition.");
		}
		return new Transition(transition);
	}

	public void Take(bool immediately = true)
	{
		Call(MethodName.Take, immediately);
	}
}
