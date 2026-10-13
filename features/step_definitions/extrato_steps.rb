Given('que eu estou na página inicial') do
  visit '/home'
end

When('eu clico no botão {string} no topo da página') do |texto_botao|
  within('header') do
    click_on texto_botao
  end
end

Then('eu devo ser redirecionado para a página {string}') do |caminho|
  expect(page).to have_current_path(caminho)
end

# Aqui eu uso uma regex para capturar o final da frase dos cards
Then(/^eu devo ver um card com o (.*)$/) do |conteudo_card|
  expect(page).to have_css('.card', text: /#{conteudo_card}/i) # Procura por uma div com a classe .card que contenha o texto de "conteudo_card"
end

Then('eu devo ver uma tabela contendo os cabeçalhos {string}, {string}, {string}, {string}, {string} e {string}') do |c1, c2, c3, c4, c5, c6|
  within('table thead') do
    expect(page).to have_selector('th', text: c1)
    expect(page).to have_selector('th', text: c2)
    expect(page).to have_selector('th', text: c3)
    expect(page).to have_selector('th', text: c4)
    expect(page).to have_selector('th', text: c5)
    expect(page).to have_selector('th', text: c6)
  end
end

Then('a tabela deve exibir a linha com {string}, {string}, {string}, {string}, {string} e {string}') do |data, evento, restaurante, metodo, valor, comprovante|
  within('table tbody') do
    linha = find('tr', text: data)  
    expect(linha).to have_content(evento)
    expect(linha).to have_content(restaurante)
    expect(linha).to have_content(metodo)
    expect(linha).to have_content(valor)
    expect(linha).to have_content(comprovante)
  end
end

# Testes específicos do sad path

Then(/^eu devo ver um card com o (.*) vazio$/) do |nome_do_card|
  # Encontra o card pelo título capturado (ex: "total gasto no mês")
  within('.card', text: /#{nome_do_card}/i) do
    # Verifica se o conteúdo reflete um estado vazio/zerado. 
    # Adapte as strings abaixo (como "R$ 0,00" ou "0") para combinar com o que você vai renderizar no seu HAML.
    texto = page.text
    expect(texto).to match(/R\$ 0,00|0\b/i)
  end
end

Then('a tabela deve estar vazia') do
  within('table') do    
    tbody = find('tbody')
    expect(tbody).to have_no_selector('tr')
  end
end
