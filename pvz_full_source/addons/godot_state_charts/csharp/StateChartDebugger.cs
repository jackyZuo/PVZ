using System;
using Godot;

namespace GodotStateCharts;

public class StateChartDebugger : NodeWrapper
{
	public class MethodName : Node.MethodName
	{
		public static readonly string DebugNode = "debug_node";

		public static readonly string AddHistoryEntry = "add_history_entry";
	}

	private StateChartDebugger(Node wrapped)
		: base(wrapped)
	{
	}

	public static StateChartDebugger Of(Node stateChartDebugger)
	{
		if (!(stateChartDebugger.GetScript().As<Script>() is GDScript gDScript) || !gDScript.ResourcePath.EndsWith("state_chart_debugger.gd"))
		{
			throw new ArgumentException("Given node is not a state chart debugger.");
		}
		return new StateChartDebugger(stateChartDebugger);
	}

	public void DebugNode(Node node)
	{
		Call(MethodName.DebugNode, node);
	}

	public void AddHistoryEntry(string text)
	{
		Call(MethodName.AddHistoryEntry, text);
	}
}
