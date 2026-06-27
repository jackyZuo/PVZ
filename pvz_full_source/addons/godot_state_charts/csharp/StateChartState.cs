using System;
using Godot;

namespace GodotStateCharts;

public class StateChartState : NodeWrapper
{
	public class SignalName : Node.SignalName
	{
		public static readonly StringName StateEntered = "state_entered";

		public static readonly StringName StateExited = "state_exited";

		public static readonly StringName EventReceived = "event_received";

		public static readonly StringName StateProcessing = "state_processing";

		public static readonly StringName StatePhysicsProcessing = "state_physics_processing";

		public static readonly StringName StateStepped = "state_stepped";

		public static readonly StringName StateInput = "state_input";

		public static readonly StringName StateUnhandledInput = "state_unhandled_input";

		public static readonly StringName TransitionPending = "transition_pending";
	}

	public bool Active => Wrapped.Get("active").As<bool>();

	public event Action StateEntered
	{
		add
		{
			Wrapped.Connect(SignalName.StateEntered, Callable.From(value));
		}
		remove
		{
			Wrapped.Disconnect(SignalName.StateEntered, Callable.From(value));
		}
	}

	public event Action StateExited
	{
		add
		{
			Wrapped.Connect(SignalName.StateExited, Callable.From(value));
		}
		remove
		{
			Wrapped.Disconnect(SignalName.StateExited, Callable.From(value));
		}
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

	public event Action<float> StateProcessing
	{
		add
		{
			Wrapped.Connect(SignalName.StateProcessing, Callable.From(value));
		}
		remove
		{
			Wrapped.Disconnect(SignalName.StateProcessing, Callable.From(value));
		}
	}

	public event Action<float> StatePhysicsProcessing
	{
		add
		{
			Wrapped.Connect(SignalName.StatePhysicsProcessing, Callable.From(value));
		}
		remove
		{
			Wrapped.Disconnect(SignalName.StatePhysicsProcessing, Callable.From(value));
		}
	}

	public event Action StateStepped
	{
		add
		{
			Wrapped.Connect(SignalName.StateStepped, Callable.From(value));
		}
		remove
		{
			Wrapped.Disconnect(SignalName.StateStepped, Callable.From(value));
		}
	}

	public event Action<InputEvent> StateInput
	{
		add
		{
			Wrapped.Connect(SignalName.StateInput, Callable.From(value));
		}
		remove
		{
			Wrapped.Disconnect(SignalName.StateInput, Callable.From(value));
		}
	}

	public event Action<InputEvent> StateUnhandledInput
	{
		add
		{
			Wrapped.Connect(SignalName.StateUnhandledInput, Callable.From(value));
		}
		remove
		{
			Wrapped.Disconnect(SignalName.StateUnhandledInput, Callable.From(value));
		}
	}

	public event Action<float, float> TransitionPending
	{
		add
		{
			Wrapped.Connect(SignalName.TransitionPending, Callable.From(value));
		}
		remove
		{
			Wrapped.Disconnect(SignalName.TransitionPending, Callable.From(value));
		}
	}

	protected StateChartState(Node wrapped)
		: base(wrapped)
	{
	}

	public static StateChartState Of(Node state)
	{
		if (!(state.GetScript().As<Script>() is GDScript gDScript) || !gDScript.ResourcePath.EndsWith("state.gd"))
		{
			throw new ArgumentException("Given node is not a state.");
		}
		return new StateChartState(state);
	}
}
