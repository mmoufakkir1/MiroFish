"""
Configuration management.

Loads environment variables from the project root `.env` file and resolves
active LLM settings for either local models or OpenRouter.
"""

import os

from dotenv import load_dotenv


project_root_env = os.path.join(os.path.dirname(__file__), "../../.env")

if os.path.exists(project_root_env):
    load_dotenv(project_root_env, override=True)
else:
    load_dotenv(override=True)


class Config:
    """Application configuration."""

    SECRET_KEY = os.environ.get("SECRET_KEY", "mirofish-secret-key")
    DEBUG = os.environ.get("FLASK_DEBUG", "True").lower() == "true"
    JSON_AS_ASCII = False

    LOCAL_MODELS_ENABLED = os.environ.get("LOCAL_MODELS_ENABLED", "false").lower() == "true"

    OPENROUTER_API_KEY = os.environ.get("LLM_API_KEY", "").strip()
    OPENROUTER_BASE_URL = os.environ.get("LLM_BASE_URL", "https://openrouter.ai/api/v1").strip()
    OPENROUTER_MODEL_NAME = os.environ.get("LLM_MODEL_NAME", "").strip()

    LOCAL_LLM_API_KEY = os.environ.get("LOCAL_LLM_API_KEY", "local").strip()
    LOCAL_LLM_BASE_URL = os.environ.get("LOCAL_LLM_BASE_URL", "http://localhost:11434/v1").strip()
    LOCAL_LLM_MODEL_NAME = os.environ.get("LOCAL_LLM_MODEL_NAME", "").strip()

    OPENROUTER_BOOST_API_KEY = os.environ.get("LLM_BOOST_API_KEY", "").strip()
    OPENROUTER_BOOST_BASE_URL = os.environ.get("LLM_BOOST_BASE_URL", "").strip()
    OPENROUTER_BOOST_MODEL_NAME = os.environ.get("LLM_BOOST_MODEL_NAME", "").strip()

    LOCAL_LLM_BOOST_API_KEY = os.environ.get("LOCAL_LLM_BOOST_API_KEY", "local").strip()
    LOCAL_LLM_BOOST_BASE_URL = os.environ.get("LOCAL_LLM_BOOST_BASE_URL", "http://localhost:11434/v1").strip()
    LOCAL_LLM_BOOST_MODEL_NAME = os.environ.get("LOCAL_LLM_BOOST_MODEL_NAME", "").strip()

    DEFAULT_LLM_BASE_URL = "https://api.openai.com/v1"
    DEFAULT_LLM_MODEL_NAME = "gpt-4o-mini"

    ZEP_API_KEY = os.environ.get("ZEP_API_KEY")

    MAX_CONTENT_LENGTH = 50 * 1024 * 1024
    UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), "../uploads")
    ALLOWED_EXTENSIONS = {"pdf", "md", "txt", "markdown"}

    DEFAULT_CHUNK_SIZE = 500
    DEFAULT_CHUNK_OVERLAP = 50

    OASIS_DEFAULT_MAX_ROUNDS = int(os.environ.get("OASIS_DEFAULT_MAX_ROUNDS", "10"))
    OASIS_SIMULATION_DATA_DIR = os.path.join(os.path.dirname(__file__), "../uploads/simulations")

    OASIS_TWITTER_ACTIONS = [
        "CREATE_POST",
        "LIKE_POST",
        "REPOST",
        "FOLLOW",
        "DO_NOTHING",
        "QUOTE_POST",
    ]
    OASIS_REDDIT_ACTIONS = [
        "LIKE_POST",
        "DISLIKE_POST",
        "CREATE_POST",
        "CREATE_COMMENT",
        "LIKE_COMMENT",
        "DISLIKE_COMMENT",
        "SEARCH_POSTS",
        "SEARCH_USER",
        "TREND",
        "REFRESH",
        "DO_NOTHING",
        "FOLLOW",
        "MUTE",
    ]

    REPORT_AGENT_MAX_TOOL_CALLS = int(os.environ.get("REPORT_AGENT_MAX_TOOL_CALLS", "5"))
    REPORT_AGENT_MAX_REFLECTION_ROUNDS = int(os.environ.get("REPORT_AGENT_MAX_REFLECTION_ROUNDS", "2"))
    REPORT_AGENT_TEMPERATURE = float(os.environ.get("REPORT_AGENT_TEMPERATURE", "0.5"))

    @classmethod
    def _resolve_provider_config(cls, use_local=False, use_boost=False):
        if use_local:
            api_key = cls.LOCAL_LLM_BOOST_API_KEY if use_boost else cls.LOCAL_LLM_API_KEY
            base_url = cls.LOCAL_LLM_BOOST_BASE_URL if use_boost else cls.LOCAL_LLM_BASE_URL
            model_name = cls.LOCAL_LLM_BOOST_MODEL_NAME if use_boost else cls.LOCAL_LLM_MODEL_NAME
            provider = "local"
        else:
            api_key = cls.OPENROUTER_BOOST_API_KEY if use_boost else cls.OPENROUTER_API_KEY
            base_url = cls.OPENROUTER_BOOST_BASE_URL if use_boost else cls.OPENROUTER_BASE_URL
            model_name = cls.OPENROUTER_BOOST_MODEL_NAME if use_boost else cls.OPENROUTER_MODEL_NAME
            provider = "openrouter"

        if provider == "local" and not api_key:
            api_key = "local"

        raw_model_name = model_name.strip()

        return {
            "provider": provider,
            "api_key": api_key.strip(),
            "base_url": (base_url or cls.DEFAULT_LLM_BASE_URL).strip(),
            "model_name": (raw_model_name or cls.DEFAULT_LLM_MODEL_NAME).strip(),
            "raw_model_name": raw_model_name,
            "is_local": provider == "local",
            "is_boost": use_boost,
        }

    @classmethod
    def get_llm_config(cls, use_boost=False):
        local_config = cls._resolve_provider_config(use_local=True, use_boost=use_boost)
        openrouter_config = cls._resolve_provider_config(use_local=False, use_boost=use_boost)

        if cls.LOCAL_MODELS_ENABLED and local_config["raw_model_name"]:
            return local_config

        if openrouter_config["api_key"] and openrouter_config["raw_model_name"]:
            return openrouter_config

        if local_config["raw_model_name"]:
            return local_config

        return openrouter_config

    @classmethod
    def validate(cls):
        errors = []
        llm_config = cls.get_llm_config()
        if not llm_config["api_key"]:
            errors.append("No LLM API key configured for the active provider")
        if not llm_config["model_name"]:
            errors.append("No LLM model configured for the active provider")
        if not cls.ZEP_API_KEY:
            errors.append("ZEP_API_KEY is not configured")
        return errors


_active_llm = Config.get_llm_config()
Config.LLM_PROVIDER = _active_llm["provider"]
Config.LLM_API_KEY = _active_llm["api_key"]
Config.LLM_BASE_URL = _active_llm["base_url"]
Config.LLM_MODEL_NAME = _active_llm["model_name"]

_active_boost_llm = Config.get_llm_config(use_boost=True)
Config.LLM_BOOST_PROVIDER = _active_boost_llm["provider"]
Config.LLM_BOOST_API_KEY = _active_boost_llm["api_key"]
Config.LLM_BOOST_BASE_URL = _active_boost_llm["base_url"]
Config.LLM_BOOST_MODEL_NAME = _active_boost_llm["model_name"]
