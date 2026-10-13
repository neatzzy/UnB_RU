# Cria o usuário no banco de dados de teste antes de o cenário rodar.
Given('que existe um estudante cadastrado com o e-mail {string} e senha {string}') do |email, senha|
  User.create!(
    nome: 'Estudante Teste',
    email: email,
    password: senha
  )
end

Given('que eu estou na página de login') do
  visit '/login'
end

When('eu preencho o campo {string} com {string}') do |nome_do_campo, valor|
  fill_in nome_do_campo, with: valor
end

When('eu deixo o campo {string} vazio') do |nome_do_campo|
  fill_in nome_do_campo, with: ""
end

When('eu clico no botão {string}') do |texto_botao|
  click_button texto_botao
end

Then('eu devo ser redirecionado para a página inicial') do
  expect(page).to have_current_path('/home')
end

Then('eu devo permanecer na página de login') do
  expect(page).to have_current_path(new_user_session_path)
end
