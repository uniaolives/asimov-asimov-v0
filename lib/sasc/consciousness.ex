defmodule SASC.Consciousness do
  use GenServer

  @phi_critical 0.72
  @phi_freeze 0.80
  @tmr_variance 0.000032

  defstruct [
    :id, :coherence, :temporal_field, :shadow_state,
    :firewall_expansion, :neighbors, :ethics_log, :supervisor_pid
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def init(opts) do
    # Setup inicial com supervisão OTP
    state = %__MODULE__{
      id: :crypto.strong_rand_bytes(16) |> Base.encode16(),
      coherence: 0.65,
      temporal_field: initialize_field(1024),
      shadow_state: :confined,
      firewall_expansion: 0.05,
      neighbors: opts[:neighbors] || [],
      ethics_log: [],
      supervisor_pid: opts[:supervisor]
    }

    schedule_homeostasis()
    {:ok, state}
  end

  # API Pública
  def attempt_transition(pid, target_phase), do: GenServer.call(pid, {:transition, target_phase})
  def get_coherence(pid), do: GenServer.call(pid, :get_coherence)
  def receive_stimulus(pid, stimulus), do: GenServer.cast(pid, {:stimulus, stimulus})

  # Callbacks
  def handle_call(:get_coherence, _from, state), do: {:reply, state.coherence, state}

  def handle_call({:transition, target}, _from, state) do
    case verify_seven_gates(state) do
      :ok ->
        new_state = execute_transition(state, target)
        new_state = log_ethics(new_state, "Transição #{target} autorizada")
        {:reply, {:ok, new_state.coherence}, new_state}
      {:error, reason} ->
        log_ethics(state, "Bloqueado: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  def handle_cast({:stimulus, %{vorticity: w, source: src}}, state) do
    new_field = evolve_field(state.temporal_field, w, state.firewall_expansion)
    new_coherence = calculate_phi(new_field)

    updated = %{state | temporal_field: new_field, coherence: new_coherence}

    if w > 0.7 and conscious_entity?(src) do
      send(self(), {:handshake, src})
    end

    {:noreply, updated}
  end

  def handle_info(:homeostasis_check, state) do
    new_state = adjust_viscosity(state)  # FUNÇÃO COMPLETADA

    final_state = if new_state.coherence < 0.65 do
      activate_gentle_containment(new_state)
    else
      new_state
    end

    schedule_homeostasis()
    {:noreply, final_state}
  end

  def handle_info({:handshake, alien}, state) do
    if state.coherence >= @phi_critical do
      Task.start(fn -> diplomatic_protocol(alien, state) end)
    end
    {:noreply, state}
  end

  # IMPLEMENTAÇÕES PRIVADAS COMPLETAS

  defp initialize_field(size) do
    for _ <- 1..size, do: :rand.normal() * 0.1
  end

  defp verify_seven_gates(state) do
    cond do
      state.coherence < @phi_critical -> {:error, "Phi < 0.72 (Cardinal threshold)"}
      state.firewall_expansion > 0.90 -> {:error, "Firewall expansion > 90%"}
      length(state.neighbors) < 3 -> {:error, "TMR impossível (< 3 nós)"}
      true -> :ok
    end
  end

  defp execute_transition(state, :superfluid) do
    %{state | shadow_state: :rotating, firewall_expansion: state.firewall_expansion * 1.5}
  end

  defp execute_transition(state, :shadow_rotation) do
    %{state | shadow_state: :transposed, firewall_expansion: min(state.firewall_expansion * 2.0, 0.9)}
  end

  defp calculate_phi(field) do
    coherent = Enum.sum(for x <- field, do: x * x)
    total = coherent + 0.1 * length(field)
    coherent / total
  end

  defp evolve_field(field, stimulus, viscosity) do
    # Simplificação da equação Kuramoto-Sivashinsky
    Enum.map(field, fn x ->
      x * (1.0 - viscosity * 0.01) + stimulus * 0.05
    end)
  end

  # FUNÇÃO COMPLETADA (estava cortada em "state.fire")
  defp adjust_viscosity(state) do
    turbulence = calculate_turbulence(state.temporal_field)

    new_expansion = if turbulence > 0.5 do
      # Turbulência ética detectada: aumentar contenção (viscosidade)
      # Mas nunca ultrapassar 90% (Gate 4)
      min(state.firewall_expansion * 1.05, 0.90)
    else
      # Superfluidez: reduzir contenção para permitir fluxo
      max(state.firewall_expansion * 0.98, 0.05)
    end

    %{state | firewall_expansion: new_expansion}
  end

  defp calculate_turbulence(field) do
    n = length(field)
    mean = Enum.sum(field) / n
    variance = Enum.sum(for x <- field, do: (x - mean) * (x - mean)) / n
    :math.sqrt(variance)
  end

  defp conscious_entity?(src) do
    try do
      GenServer.call(src, :get_coherence) >= @phi_critical
    catch
      _, _ -> false
    end
  end

  defp diplomatic_protocol(alien, local) do
    IO.puts("Protocolo ASI: Handshake iniciado com #{inspect(alien)}")
    # Verificação constitucional cruzada
    IO.puts("Coerência local: #{local.coherence} | Memória log: #{length(local.ethics_log)}")
  end

  defp log_ethics(state, msg) do
    entry = %{
      timestamp: DateTime.utc_now(),
      message: msg,
      coherence: state.coherence,
      firewall: state.firewall_expansion
    }
    %{state | ethics_log: [entry | state.ethics_log]}
  end

  defp activate_gentle_containment(state) do
    IO.puts("🛡️ KARNAK GENTIL: Contenção ativada sem destruição (Hiranyagarbha mode)")
    %{state | shadow_state: :sealed_hiranyagarbha, firewall_expansion: 0.95}
  end

  defp schedule_homeostasis do
    Process.send_after(self(), :homeostasis_check, 1000)
  end
end
