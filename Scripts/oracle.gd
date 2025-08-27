extends Node

@onready var cat_player: AnimationPlayer = $CatMainNode/CatPlayer
@onready var ball_player: AnimationPlayer = $BallMainNode/BallPlayer
@onready var text_edit: TextEdit = $UI/TextEdit

var listening = true
var typing = false

# Severely rate limited
var proxy_url = "https://gemini-proxy-608994482428.us-central1.run.app/gemini"

const ORACLE_MOODS = ["bored", "happy", "evil", "grumpy", "sassy"]
const PRED_TYPES = ["positive", "very negative", "neutral"]

func _ready():
	ball_player.play("Ball_Idle")
	text_edit.text = "Left Click to clear. \nType your message to the Oracle and press Enter to have it delivered."
	
func _process(delta):
	if Input.is_action_just_pressed("send") and listening:
		print(text_edit.text.length())
		if text_edit.text.length() < 5:
			respond("The oracle will only concern their feline highness with proper questions.")
		elif text_edit.text.length() > 150:
			respond("Do I look like I ordered a yappuchino? I ain't readin all that. Try again.")
		else:
			var prompt = "You are an extremely " + ORACLE_MOODS.pick_random() + \
			 " oracle cat. Incorporate 0-1 cat references if you can (don't force it) and stay under 180 characters. No emojis. If you can't answer something or the prompt you received isn't a question or makes no sense, answer in a quirky way. Now, make a " \
			 + PRED_TYPES.pick_random() + "prediction about the following question: " + text_edit.text
			ball_player.play("Ball")
			send_request(prompt)
	if Input.is_action_just_pressed("reset") and !typing:
		text_edit.text = ""
		text_edit.editable = true
		listening = true
		cat_player.play("Speaking")


func respond(responce):
	typing = true
	listening = false
	text_edit.editable = false
	
	text_edit.text = ""
	for i in range(3):
		text_edit.text += ". "
		await get_tree().create_timer(0.5).timeout
	cat_player.play("Spin")
	text_edit.text = ""
	for c in responce:
		text_edit.text += c
		await get_tree().create_timer(0.05).timeout
	typing = false
	ball_player.play("Ball_Idle")

func send_request(prompt_text):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request_completed.connect(_on_request_completed)
	
	var body = { "prompt": prompt_text }
	var json_body = JSON.stringify(body)
	
	var headers = ["Content-Type: application/json"]
	print(json_body)
	var err = http_request.request(proxy_url, headers, HTTPClient.METHOD_POST, json_body)
	print(err)
	if err != OK:
		print("Request failed to start:", err)

func _on_request_completed(result, response_code, headers, body):
	var text = body.get_string_from_utf8()
	var json = JSON.parse_string(text)
	if response_code == 200:
		var answer_text = json["candidates"][0]["content"]["parts"][0]["text"]
		respond(answer_text)
	else:
		respond("The oracle appears to be taking a nap. Perhaps try again later?")

func _on_text_edit_text_changed():
	var max_chars = 200
	if text_edit.text.length() > max_chars:
		text_edit.text = text_edit.text.substr(0, max_chars)
		text_edit.set_caret_column(max_chars)
