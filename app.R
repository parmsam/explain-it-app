# Load required libraries
library(shiny)
library(ellmer)
library(jsonlite)

ellmer_chat <- function(prompt){
  chat <- ellmer::chat_openai(
    system_prompt = paste0(readLines("system-prompt.md"), collapse = "\n"), 
    model = "gpt-4o-mini"
  )
  chat$chat(prompt)
}


# Define the UI
ui <- fluidPage(
  tags$style(type='text/css', '#response {white-space: pre-wrap;}'),
  titlePanel("LevelUp Explainer - GPT-4o mini"),
  sidebarLayout(
    sidebarPanel(
      numericInput("levels", "Select the number of explanation levels:", value = 3, min = 1, max = 5),
      sliderInput("level_slider", "Select Level:", min = 1, max = 5, value = 3, step = 1),
      textAreaInput("question", "Enter your question:", "What is the theory of relativity?"),
      actionButton("submit", "Generate Explanation")
    ),
    
    mainPanel(
      h3("Explanation at Selected Level:"),
      verbatimTextOutput("response")
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
  
  observeEvent(input$submit, {
    
    # Get the question and level from the inputs
    question <- input$question
    level <- input$level_slider
    
    # Use ellmer to query GPT-4o mini with the defined prompt
    response <- ellmer_chat(prompt())
    
    # Output the result
    output$response <- renderText({
      response
    })
  })
}

# Run the application
shinyApp(ui = ui, server = server)
