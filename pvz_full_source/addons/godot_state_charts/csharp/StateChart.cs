using System;
using Godot;

namespace GodotStateCharts;

public class StateChart : NodeWrapper
{
	public class SignalName : Node.SignalName
	{
		public static readonly StringName EventReceived = "event_received";
	}

	public class MethodName : Node.MethodName
	{
		public static readonly StringName SendEvent = "send_event";

		public static readonly StringName SetExpressionProperty = "set_expression_property";

		public static readonly StringName GetExpressionProperty = "get_expression_property";

		public static readonly StringName Step = "step";
	}

	public event Action<StringName> EventReceived
	{
		add
		{
			Wrapped.Connect(SignalName.EventReceived, Callable.From(value));
		}
		remove
		{
			Wrapped.Disconnect(SignalName.EventReceived, Callable.From(value));
		}
	}

	protected StateChart(Node wrapped)
		: base(wrapped)
	{
	}

	public static StateChart Of(Node stateChart)
	{
		if (!(stateChart.GetScript().As<Script>() is GDScript gdScript) || !gdScript.ResourcePath.EndsWith("state_chart.gd"))
		{
			throw new ArgumentException("Given node is not a state chart.");
		}
		return new StateChart(stateChart);
	}

	public void SendEvent(string eventName)
	{
		Call(MethodName.SendEvent, eventName);
	}

	public void SetExpressionProperty(string name, Variant value)
	{
		Call(MethodName.SetExpressionProperty, name, value);
	}

	public T GetExpressionProperty<[MustBeVariant] T>(string name, T defaultValue = default(T))
	{
		return Call(MethodName.GetExpressionProperty, name, Variant.From(in defaultValue)).As<T>();
	}

	public void Step()
	{
		Call(MethodName.Step);
	}
}
