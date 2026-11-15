require "test_helper"

# Turno criado aqui, e não em fixtures: o banco de teste também é usado pelo Cucumber.
class TipoRefeicaoTest < ActiveSupport::TestCase
  setup do
    @almoco = TipoRefeicao.create!(nome: "Almoço", hora_inicio: "11:00", hora_fim: "14:00")
  end

  test "granularidade com casas decimais é recusada" do
    assert_not @almoco.configurar_time_frames(granularidade: "15.5", tolerancia: "3")
    assert_includes @almoco.errors[:base], "A granularidade deve ser um número"
    assert_empty @almoco.time_frames.reload
  end

  test "tolerância negativa é recusada" do
    assert_not @almoco.configurar_time_frames(granularidade: "15", tolerancia: "-1")
    assert_includes @almoco.errors[:base], "A tolerância deve ser um número inteiro maior ou igual a 0"
  end

  test "reenviar a mesma granularidade mantém as janelas e só muda a tolerância" do
    @almoco.configurar_time_frames(granularidade: "15", tolerancia: "3")
    janelas = @almoco.time_frames.reload.ids

    assert @almoco.configurar_time_frames(granularidade: "15", tolerancia: "5")
    assert_equal janelas, @almoco.time_frames.reload.ids
    assert_equal 5, @almoco.reload.tolerancia_minutos
  end

  test "reenviar a mesma granularidade não apaga as inscrições dos alunos" do
    @almoco.configurar_time_frames(granularidade: "15", tolerancia: "3")
    users(:genaina).inscricoes_fastpass.create!(time_frame: @almoco.time_frames.first, data: Date.current)

    assert @almoco.configurar_time_frames(granularidade: "15", tolerancia: "5")
    assert_equal 1, @almoco.inscricoes_fastpass.count
  end

  test "mudar a granularidade recria as janelas" do
    @almoco.configurar_time_frames(granularidade: "15", tolerancia: "3")

    assert @almoco.configurar_time_frames(granularidade: "30", tolerancia: "3")
    assert_equal 6, @almoco.time_frames.reload.size
  end

  test "mudar o horário apaga as janelas e a configuração antiga" do
    @almoco.configurar_time_frames(granularidade: "15", tolerancia: "3")
    @almoco.update!(hora_fim: "13:00")
    @almoco.reload

    assert_empty @almoco.time_frames
    assert_nil @almoco.granularidade_minutos
    assert_nil @almoco.tolerancia_minutos
  end
end
