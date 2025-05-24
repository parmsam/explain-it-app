# Load required libraries
library(shiny)
library(bslib)
library(ellmer)
library(jsonlite)

read_prompt_md <- function(path){
  paste0(readLines(path), collapse = "\n")
}

ellmer_chat <- function(prompt, system_prompt = "system-prompt.md", model = "gpt-4o-mini"){
  chat <- ellmer::chat_openai(
    system_prompt = read_prompt_md(system_prompt),
    model = model
  )
  chat$chat(prompt)
}

# Define the UI
ui <- fluidPage(
  theme = bs_theme(preset = "bootstrap"),
  tags$style(type='text/css', '#response {white-space: pre-wrap;}'),
  titlePanel("5 Levels - GPT-4o mini"),
  h3(markdown("An LLM explains a complex subject in five levels of complexity. \n Inspired by the [Wired video series](https://www.youtube.com/playlist?list=PLibNZv5Zd0dyCoQ6f4pdXUFnpAIlKgm3N)")),
  sidebarLayout(
    sidebarPanel(
      numericInput("levels", "Select the number of explanation levels:", value = 5, min = 1, max = 10),
      sliderInput("level_slider", "Select Level:", min = 1, max = 5, value = 3, step = 1),
      textAreaInput("question", "Enter your question:", "What is the theory of relativity?"),
      actionButton("submit", "Generate Explanation"),
      actionButton("randomQuestion", "Random Question")
    ),
    mainPanel(
      h4("Explanation at Selected Level:"),
      verbatimTextOutput("response", placeholder = TRUE)
    )
  )
)

# Define the server logic
server <- function(input, output, session) {
  
  # Update slider max when levels input changes
  observeEvent(input$levels, {
    updateSliderInput(session, "level_slider", max = input$levels)
    # Optionally, reset value if current value > new max
    if (input$level_slider > input$levels) {
      updateSliderInput(session, "level_slider", value = input$levels)
    }
  })

  # Create the JSON prompt for the ellmer chat
  prompt <- reactive({
    x <- list(
      user = list(
        understanding = input$level_slider,
        complexity = input$levels
      ),
      question = input$question
    )
    jsonlite::serializeJSON(x)
  })
  
  observeEvent(input$randomQuestion, {
    random_questions <- c("What is quantum mechanics?", "Explain black holes.", "What is the theory of evolution?", "Describe the Big Bang theory.", "What is artificial intelligence?")
    random_question <- sample(random_questions, 1)
    # Update the question input with the random question
    updateTextAreaInput(session, "question", value = random_question)
  })
  
  observeEvent(input$submit, {
    # Show loading notification
    loading_id <- showNotification("Generating explanation...", duration = NULL, closeButton = FALSE, type = "message")
    
    # Use ellmer to query GPT-4o mini with the defined prompt
    response <- ellmer_chat(prompt())
    
    # Output the result
    output$response <- renderText({
      response
    })
    
    # Remove loading notification
    removeNotification(loading_id)
  })
}

# Run the application
shinyApp(ui = ui, server = server)
