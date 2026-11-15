require "test_helper"

# Turnos e janelas são criados aqui, e não em fixtures: os fixtures ficam no banco
# de teste que o Cucumber também usa, e um "Almoço" fixo quebraria a #16.
class Estudante::InscricoesFastpassControllerTest < ActionDispatch::IntegrationTest
  setup do
    @aluno = users(:genaina)
    @almoco = TipoRefeicao.create!(nome: "Almoço", hora_inicio: "11:00", hora_fim: "14:00")
    @janela = @almoco.time_frames.create!(inicio: "12:00", fim: "12:15")
    @outra_janela = @almoco.time_frames.create!(inicio: "12:15", fim: "12:30")
  end

  test "exige login" do
    assert_no_difference("InscricaoFastpass.count") do
      post fastpass_inscricoes_path, params: { time_frame_id: @janela.id }
    end

    assert_redirected_to login_path
  end

  test "funcionário não vê nem se inscreve no FastPass" do
    funcionario = User.create!(nome: "Servidor", matricula: "1984999", password: "senha123", perfil: :funcionario)
    entrar_como funcionario

    get fastpass_path
    assert_redirected_to home_path

    assert_no_difference("InscricaoFastpass.count") do
      post fastpass_inscricoes_path, params: { time_frame_id: @janela.id }
    end
    assert_redirected_to home_path
    assert_equal "O FastPass é exclusivo para alunos", flash[:alert]
  end

  test "inscreve o aluno com status inscrito" do
    entrar_como @aluno

    assert_difference("InscricaoFastpass.count", 1) do
      post fastpass_inscricoes_path, params: { time_frame_id: @janela.id }
    end

    inscricao = @aluno.inscricoes_fastpass.last
    assert_redirected_to fastpass_path
    assert_equal "Inscrição no sorteio realizada com sucesso", flash[:notice]
    assert_equal @janela, inscricao.time_frame
    assert_equal Date.current, inscricao.data
    assert inscricao.inscrito?
  end

  test "pede para escolher um horário quando nenhuma janela é enviada" do
    entrar_como @aluno

    assert_no_difference("InscricaoFastpass.count") do
      post fastpass_inscricoes_path, params: { time_frame_id: "" }
    end

    assert_redirected_to fastpass_path
    assert_equal "Escolha um horário", flash[:alert]
  end

  test "recusa segunda inscrição no mesmo turno" do
    entrar_como @aluno
    @aluno.inscricoes_fastpass.create!(time_frame: @janela, data: Date.current)

    assert_no_difference("InscricaoFastpass.count") do
      post fastpass_inscricoes_path, params: { time_frame_id: @outra_janela.id }
    end

    assert_redirected_to fastpass_path
    assert_equal "Você já possui uma inscrição para o Almoço. Cancele a atual para alterar o horário.", flash[:alert]
  end

  test "cancela a própria inscrição" do
    entrar_como @aluno
    inscricao = @aluno.inscricoes_fastpass.create!(time_frame: @janela, data: Date.current)

    # Antes das 10:00: o Almoço começa às 11:00 e o resultado sai 1 hora antes.
    assert_difference("InscricaoFastpass.count", -1) do
      travel_to(hoje_as(9, 30)) { delete fastpass_inscricao_path(inscricao) }
    end

    assert_redirected_to fastpass_path
    assert_equal "Inscrição cancelada", flash[:notice]
  end

  test "não cancela na última hora antes do turno, mesmo sem o botão na tela" do
    entrar_como @aluno
    inscricao = @aluno.inscricoes_fastpass.create!(time_frame: @janela, data: Date.current)

    assert_no_difference("InscricaoFastpass.count") do
      travel_to(hoje_as(10, 30)) { delete fastpass_inscricao_path(inscricao) }
    end

    assert_redirected_to fastpass_path
    assert_match "sorteio já foi realizado", flash[:alert]
  end

  test "não cancela a inscrição de outro aluno" do
    entrar_como @aluno
    outro = User.create!(nome: "Outro Aluno", matricula: "2023999999", password: "senha123")
    inscricao = outro.inscricoes_fastpass.create!(time_frame: @janela, data: Date.current)

    assert_no_difference("InscricaoFastpass.count") do
      delete fastpass_inscricao_path(inscricao)
    end

    assert_response :not_found
  end

  test "não cancela inscrição já contemplada no sorteio" do
    entrar_como @aluno
    inscricao = @aluno.inscricoes_fastpass.create!(time_frame: @janela, data: Date.current, status: :contemplado)

    assert_no_difference("InscricaoFastpass.count") do
      delete fastpass_inscricao_path(inscricao)
    end

    assert_redirected_to fastpass_path
    assert_match "sorteio já foi realizado", flash[:alert]
    assert inscricao.reload.contemplado?
  end

  private

  def hoje_as(hora, minuto)
    Time.zone.today.in_time_zone.change(hour: hora, min: minuto)
  end
end
