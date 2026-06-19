using Godot;

namespace GodotStateCharts;

public abstract class NodeWrapper
{
	protected readonly Node Wrapped;

	protected NodeWrapper(Node wrapped)
	{
		Wrapped = wrapped;
	}

	public Error Connect(StringName signal, Callable method, uint flags = 0u)
	{
		return Wrapped.Connect(signal, method, flags);
	}

	public Variant CallDeferred(string method, params Variant[] args)
	{
		return Wrapped.CallDeferred(method, args);
	}

	public Variant Call(string method, params Variant[] args)
	{
		return Wrapped.Call(method, args);
	}
}
