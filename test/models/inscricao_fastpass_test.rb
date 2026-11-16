require "test_helper"

# Turno e janelas são criados aqui, e não em fixtures: o banco de teste também é
# usado pelo Cucumber (ver inscricoes_fastpass_controller_test.rb).
class InscricaoFastpassTest < ActiveSupport::TestCase
  setup do
    @aluno = users(:genaina)
    almoco = TipoRefeicao.create!(nome: "Almoço", hora_inicio: "11:00", hora_fim: "14:00")
    @janela = almoco.time_frames.create!(inicio: "12:00", fim: "12:15")
  end

  test "o banco barra a mesma janela duas vezes no dia mesmo sem a validação" do
    InscricaoFastpass.create!(aluno: @aluno, time_frame: @janela, data: Date.current)
    repetida = InscricaoFastpass.new(aluno: @aluno, time_frame: @janela, data: Date.current)

    assert_raises(ActiveRecord::RecordNotUnique) { repetida.save(validate: false) }
  end

  test "a mesma janela em outro dia é permitida" do
    InscricaoFastpass.create!(aluno: @aluno, time_frame: @janela, data: Date.yesterday)

    assert InscricaoFastpass.new(aluno: @aluno, time_frame: @janela, data: Date.current).save
  end

  test "o início do turno usa a data da inscrição e o horário do turno" do
    inscricao = InscricaoFastpass.new(time_frame: @janela, data: Date.new(2026, 11, 20))

    assert_equal Time.zone.local(2026, 11, 20, 11, 0), inscricao.inicio_do_turno
  end

  test "o resultado é liberado a partir de 1 hora antes do turno" do
    inscricao = InscricaoFastpass.new(time_frame: @janela, data: Date.new(2026, 11, 20))

    travel_to(Time.zone.local(2026, 11, 20, 9, 59, 59)) { assert_not inscricao.resultado_liberado? }
    travel_to(Time.zone.local(2026, 11, 20, 10, 0, 0)) { assert inscricao.resultado_liberado? }
  end

  test "a inscrição de amanhã ainda não tem resultado no horário de hoje" do
    inscricao = InscricaoFastpass.new(time_frame: @janela, data: Date.new(2026, 11, 21))

    travel_to(Time.zone.local(2026, 11, 20, 10, 30)) { assert_not inscricao.resultado_liberado? }
  end
end
